//
// Copyright 2022 Signal Messenger, LLC
// SPDX-License-Identifier: AGPL-3.0-only
//

import LibSignalClient
import XCTest

@testable import SignalServiceKit

class TSOutgoingMessageTest: SSKBaseTestSwift {
    private var identityManager: OWSIdentityManager { DependenciesBridge.shared.identityManager }

    override func setUp() {
        super.setUp()
        tsAccountManager.registerForTests(localIdentifiers: .forUnitTests)
        identityManager.generateAndPersistNewIdentityKey(for: .aci)
        identityManager.generateAndPersistNewIdentityKey(for: .pni)
    }

    func testIsUrgent() {
        write { transaction in
            let otherAddress = SignalServiceAddress(phoneNumber: "+12223334444")
            let thread = TSContactThread.getOrCreateThread(withContactAddress: otherAddress, transaction: transaction)
            let messageBuilder = TSOutgoingMessageBuilder.outgoingMessageBuilder(thread: thread, messageBody: nil)
            messageBuilder.timestamp = 100
            let message = messageBuilder.build(transaction: transaction)

            XCTAssertTrue(message.isUrgent)
        }
    }

    func testShouldNotStartExpireTimerWithMessageThatDoesNotExpire() {
        write { transaction in
            let otherAci = Aci.randomForTesting()
            let otherAddress = SignalServiceAddress(serviceId: otherAci, phoneNumber: "+12223334444")
            let thread = TSContactThread.getOrCreateThread(withContactAddress: otherAddress, transaction: transaction)
            let messageBuilder = TSOutgoingMessageBuilder.outgoingMessageBuilder(thread: thread, messageBody: nil)
            messageBuilder.timestamp = 100
            let message = messageBuilder.build(transaction: transaction)

            XCTAssertFalse(message.shouldStartExpireTimer())

            message.update(withSentRecipient: ServiceIdObjC.wrapValue(otherAci), wasSentByUD: false, transaction: transaction)

            XCTAssertFalse(message.shouldStartExpireTimer())
        }
    }

    func testShouldStartExpireTimerWithSentMessage() {
        write { transaction in
            let otherAci = Aci.randomForTesting()
            let otherAddress = SignalServiceAddress(serviceId: otherAci, phoneNumber: "+12223334444")
            let thread = TSContactThread.getOrCreateThread(withContactAddress: otherAddress, transaction: transaction)
            let messageBuilder = TSOutgoingMessageBuilder.outgoingMessageBuilder(thread: thread, messageBody: nil)
            messageBuilder.timestamp = 100
            messageBuilder.expiresInSeconds = 10
            let message = messageBuilder.build(transaction: transaction)

            XCTAssertFalse(message.shouldStartExpireTimer())

            message.update(withSentRecipient: ServiceIdObjC.wrapValue(otherAci), wasSentByUD: false, transaction: transaction)

            XCTAssertTrue(message.shouldStartExpireTimer())
        }
    }

    func testShouldNotStartExpireTimerWithAttemptingOutMessage() {
        write { transaction in
            let otherAddress = SignalServiceAddress(phoneNumber: "+12223334444")
            let thread = TSContactThread.getOrCreateThread(withContactAddress: otherAddress, transaction: transaction)
            let messageBuilder = TSOutgoingMessageBuilder.outgoingMessageBuilder(thread: thread, messageBody: nil)
            messageBuilder.timestamp = 100
            messageBuilder.expiresInSeconds = 10
            let message = messageBuilder.build(transaction: transaction)

            message.updateAllUnsentRecipientsAsSending(transaction: transaction)

            XCTAssertFalse(message.shouldStartExpireTimer())
        }
    }

    func testNoPniSignatureByDefault() {
        write { transaction in
            let otherAddress = SignalServiceAddress(serviceId: Aci.randomForTesting(), phoneNumber: "+12223334444")
            let thread = TSContactThread.getOrCreateThread(withContactAddress: otherAddress, transaction: transaction)
            let messageBuilder = TSOutgoingMessageBuilder.outgoingMessageBuilder(thread: thread, messageBody: nil)
            messageBuilder.timestamp = 100
            let message = messageBuilder.build(transaction: transaction)
            let messageData = message.buildPlainTextData(thread, transaction: transaction)!
            let content = try! SSKProtoContent(serializedData: messageData)
            XCTAssertNil(content.pniSignatureMessage)
        }
    }

    func testPniSignatureWhenNeeded() {
        write { transaction in
            let otherAci = Aci.randomForTesting()
            let otherAddress = SignalServiceAddress(serviceId: otherAci, phoneNumber: "+12223334444")
            identityManager.setShouldSharePhoneNumber(with: otherAci, tx: transaction.asV2Write)

            let thread = TSContactThread.getOrCreateThread(withContactAddress: otherAddress, transaction: transaction)
            let messageBuilder = TSOutgoingMessageBuilder.outgoingMessageBuilder(thread: thread, messageBody: nil)
            messageBuilder.timestamp = 100
            let message = messageBuilder.build(transaction: transaction)
            let messageData = message.buildPlainTextData(thread, transaction: transaction)!
            let content = try! SSKProtoContent(serializedData: messageData)

            let messagePni = content.pniSignatureMessage!.pni
            XCTAssertEqual(messagePni, tsAccountManager.localPni!.rawUUID.data)

            let aciKeyPair = identityManager.identityKeyPair(for: .aci, tx: transaction.asV2Read)!.identityKeyPair
            let pniKeyPair = identityManager.identityKeyPair(for: .pni, tx: transaction.asV2Read)!.identityKeyPair
            XCTAssert(try! pniKeyPair.identityKey.verifyAlternateIdentity(
                aciKeyPair.identityKey,
                signature: content.pniSignatureMessage!.signature!))
        }
    }

    func testReceiptClearsSharePhoneNumber() {
        write { transaction in
            let otherAci = Aci.randomForTesting()
            let otherAddress = SignalServiceAddress(serviceId: otherAci, phoneNumber: "+12223334444")
            identityManager.setShouldSharePhoneNumber(with: otherAci, tx: transaction.asV2Write)

            let thread = TSContactThread.getOrCreateThread(withContactAddress: otherAddress, transaction: transaction)
            let messageBuilder = TSOutgoingMessageBuilder.outgoingMessageBuilder(thread: thread, messageBody: nil)
            messageBuilder.timestamp = Date.ows_millisecondTimestamp()
            let message = messageBuilder.build(transaction: transaction)
            let messageData = message.buildPlainTextData(thread, transaction: transaction)!

            message.update(withSentRecipient: ServiceIdObjC.wrapValue(otherAci), wasSentByUD: true, transaction: transaction)

            let messageSendLog = SSKEnvironment.shared.messageSendLogRef
            let payloadId = messageSendLog.recordPayload(messageData, for: message, tx: transaction)!
            messageSendLog.recordPendingDelivery(
                payloadId: payloadId,
                recipientAci: otherAci,
                recipientDeviceId: 1,
                message: message,
                tx: transaction
            )

            // Nothing changed yet...
            XCTAssert(identityManager.shouldSharePhoneNumber(with: otherAci, tx: transaction.asV2Read))

            message.update(
                withDeliveredRecipient: otherAddress,
                deviceId: 1,
                deliveryTimestamp: NSDate.ows_millisecondTimeStamp(),
                context: PassthroughDeliveryReceiptContext(),
                tx: transaction
            )

            XCTAssertFalse(identityManager.shouldSharePhoneNumber(with: otherAci, tx: transaction.asV2Read))
        }
    }

    func testReceiptClearsSharePhoneNumberOnlyOnLastDevice() {
        write { transaction in
            let otherAci = Aci.randomForTesting()
            let otherAddress = SignalServiceAddress(serviceId: otherAci, phoneNumber: "+12223334444")
            identityManager.setShouldSharePhoneNumber(with: otherAci, tx: transaction.asV2Write)

            let thread = TSContactThread.getOrCreateThread(withContactAddress: otherAddress, transaction: transaction)
            let messageBuilder = TSOutgoingMessageBuilder.outgoingMessageBuilder(thread: thread, messageBody: nil)
            messageBuilder.timestamp = Date.ows_millisecondTimestamp()
            let message = messageBuilder.build(transaction: transaction)
            let messageData = message.buildPlainTextData(thread, transaction: transaction)!

            message.update(withSentRecipient: ServiceIdObjC.wrapValue(otherAci), wasSentByUD: true, transaction: transaction)

            let messageSendLog = SSKEnvironment.shared.messageSendLogRef
            let payloadId = messageSendLog.recordPayload(messageData, for: message, tx: transaction)!
            messageSendLog.recordPendingDelivery(
                payloadId: payloadId,
                recipientAci: otherAci,
                recipientDeviceId: 1,
                message: message,
                tx: transaction
            )
            messageSendLog.recordPendingDelivery(
                payloadId: payloadId,
                recipientAci: otherAci,
                recipientDeviceId: 2,
                message: message,
                tx: transaction
            )

            // Nothing changed yet...
            XCTAssert(identityManager.shouldSharePhoneNumber(with: otherAci, tx: transaction.asV2Read))

            message.update(
                withDeliveredRecipient: otherAddress,
                deviceId: 1,
                deliveryTimestamp: NSDate.ows_millisecondTimeStamp(),
                context: PassthroughDeliveryReceiptContext(),
                tx: transaction
            )

            // Still waiting on device #2!
            XCTAssert(identityManager.shouldSharePhoneNumber(with: otherAci, tx: transaction.asV2Read))

            message.update(
                withDeliveredRecipient: otherAddress,
                deviceId: 2,
                deliveryTimestamp: NSDate.ows_millisecondTimeStamp(),
                context: PassthroughDeliveryReceiptContext(),
                tx: transaction
            )

            // There we go.
            XCTAssertFalse(identityManager.shouldSharePhoneNumber(with: otherAci, tx: transaction.asV2Read))
        }
    }

    func testReceiptDoesNotClearSharePhoneNumberIfNotSealedSender() {
        write { transaction in
            let otherAci = Aci.randomForTesting()
            let otherAddress = SignalServiceAddress(serviceId: otherAci, phoneNumber: "+12223334444")
            identityManager.setShouldSharePhoneNumber(with: otherAci, tx: transaction.asV2Write)

            let thread = TSContactThread.getOrCreateThread(withContactAddress: otherAddress, transaction: transaction)
            let messageBuilder = TSOutgoingMessageBuilder.outgoingMessageBuilder(thread: thread, messageBody: nil)
            messageBuilder.timestamp = Date.ows_millisecondTimestamp()
            let message = messageBuilder.build(transaction: transaction)
            let messageData = message.buildPlainTextData(thread, transaction: transaction)!

            message.update(withSentRecipient: ServiceIdObjC.wrapValue(otherAci), wasSentByUD: false, transaction: transaction)

            let messageSendLog = SSKEnvironment.shared.messageSendLogRef
            let payloadId = messageSendLog.recordPayload(messageData, for: message, tx: transaction)!
            messageSendLog.recordPendingDelivery(
                payloadId: payloadId,
                recipientAci: otherAci,
                recipientDeviceId: 1,
                message: message,
                tx: transaction
            )

            // Nothing changed yet...
            XCTAssert(identityManager.shouldSharePhoneNumber(with: otherAci, tx: transaction.asV2Read))

            message.update(
                withDeliveredRecipient: otherAddress,
                deviceId: 1,
                deliveryTimestamp: NSDate.ows_millisecondTimeStamp(),
                context: PassthroughDeliveryReceiptContext(),
                tx: transaction
            )

            // Still not changed!
            XCTAssert(identityManager.shouldSharePhoneNumber(with: otherAci, tx: transaction.asV2Read))
        }
    }

    func testReceiptDoesNotClearSharePhoneNumberIfNoPniSignature() {
        write { transaction in
            let otherAci = Aci.randomForTesting()
            let otherAddress = SignalServiceAddress(serviceId: otherAci, phoneNumber: "+12223334444")

            let thread = TSContactThread.getOrCreateThread(withContactAddress: otherAddress, transaction: transaction)
            let messageBuilder = TSOutgoingMessageBuilder.outgoingMessageBuilder(thread: thread, messageBody: nil)
            messageBuilder.timestamp = Date.ows_millisecondTimestamp()
            let message = messageBuilder.build(transaction: transaction)
            let messageData = message.buildPlainTextData(thread, transaction: transaction)!

            message.update(withSentRecipient: ServiceIdObjC.wrapValue(otherAci), wasSentByUD: true, transaction: transaction)

            let messageSendLog = SSKEnvironment.shared.messageSendLogRef
            let payloadId = messageSendLog.recordPayload(messageData, for: message, tx: transaction)!
            messageSendLog.recordPendingDelivery(
                payloadId: payloadId,
                recipientAci: otherAci,
                recipientDeviceId: 1,
                message: message,
                tx: transaction
            )

            // If we set it now...
            XCTAssertFalse(identityManager.shouldSharePhoneNumber(with: otherAci, tx: transaction.asV2Read))
            identityManager.setShouldSharePhoneNumber(with: otherAci, tx: transaction.asV2Write)

            message.update(
                withDeliveredRecipient: otherAddress,
                deviceId: 1,
                deliveryTimestamp: NSDate.ows_millisecondTimeStamp(),
                context: PassthroughDeliveryReceiptContext(),
                tx: transaction
            )

            // ...it should stay active.
            XCTAssert(identityManager.shouldSharePhoneNumber(with: otherAci, tx: transaction.asV2Read))
        }
    }

    func testReceiptDoesNotClearSharePhoneNumberIfPniHasChanged() {
        let otherAci = Aci.randomForTesting()
        let otherAddress = SignalServiceAddress(serviceId: otherAci, phoneNumber: "+12223334444")
        var message: TSOutgoingMessage!

        write { transaction in
            identityManager.setShouldSharePhoneNumber(with: otherAci, tx: transaction.asV2Write)

            let thread = TSContactThread.getOrCreateThread(withContactAddress: otherAddress, transaction: transaction)
            let messageBuilder = TSOutgoingMessageBuilder.outgoingMessageBuilder(thread: thread, messageBody: nil)
            messageBuilder.timestamp = Date.ows_millisecondTimestamp()
            message = messageBuilder.build(transaction: transaction)
            let messageData = message.buildPlainTextData(thread, transaction: transaction)!

            message.update(withSentRecipient: ServiceIdObjC.wrapValue(otherAci), wasSentByUD: true, transaction: transaction)

            let messageSendLog = SSKEnvironment.shared.messageSendLogRef
            let payloadId = messageSendLog.recordPayload(messageData, for: message, tx: transaction)!
            messageSendLog.recordPendingDelivery(
                payloadId: payloadId,
                recipientAci: otherAci,
                recipientDeviceId: 1,
                message: message,
                tx: transaction
            )
        }

        // Change our PNI, using registerForTests(...) instead of updateLocalPhoneNumber(...) because the latter kicks
        // off a request to check with the server.
        tsAccountManager.registerForTests(withLocalNumber: "+17775550199",
                                          uuid: tsAccountManager.localAci!.rawUUID,
                                          pni: UUID())

        write { transaction in
            // Changing your number resets this setting.
            XCTAssertFalse(identityManager.shouldSharePhoneNumber(with: otherAci, tx: transaction.asV2Read))
            identityManager.setShouldSharePhoneNumber(with: otherAci, tx: transaction.asV2Write)

            message.update(
                withDeliveredRecipient: otherAddress,
                deviceId: 1,
                deliveryTimestamp: NSDate.ows_millisecondTimeStamp(),
                context: PassthroughDeliveryReceiptContext(),
                tx: transaction
            )

            // Still on, because our PNI changed!
            XCTAssert(identityManager.shouldSharePhoneNumber(with: otherAci, tx: transaction.asV2Read))
        }
    }
}

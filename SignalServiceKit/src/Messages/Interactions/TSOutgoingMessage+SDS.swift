//
//  Copyright (c) 2019 Open Whisper Systems. All rights reserved.
//

import Foundation
import GRDBCipher
import SignalCoreKit

// NOTE: This file is generated by /Scripts/sds_codegen/sds_generate.py.
// Do not manually edit it, instead run `sds_codegen.sh`.

// MARK: - Typed Convenience Methods

@objc
public extension TSOutgoingMessage {
    // NOTE: This method will fail if the object has unexpected type.
    class func anyFetchOutgoingMessage(uniqueId: String,
                                   transaction: SDSAnyReadTransaction) -> TSOutgoingMessage? {
        assert(uniqueId.count > 0)

        guard let object = anyFetch(uniqueId: uniqueId,
                                    transaction: transaction) else {
                                        return nil
        }
        guard let instance = object as? TSOutgoingMessage else {
            owsFailDebug("Object has unexpected type: \(type(of: object))")
            return nil
        }
        return instance
    }

    // NOTE: This method will fail if the object has unexpected type.
    func anyUpdateOutgoingMessage(transaction: SDSAnyWriteTransaction, block: (TSOutgoingMessage) -> Void) {
        anyUpdate(transaction: transaction) { (object) in
            guard let instance = object as? TSOutgoingMessage else {
                owsFailDebug("Object has unexpected type: \(type(of: object))")
                return
            }
            block(instance)
        }
    }
}

// MARK: - SDSSerializer

// The SDSSerializer protocol specifies how to insert and update the
// row that corresponds to this model.
class TSOutgoingMessageSerializer: SDSSerializer {

    private let model: TSOutgoingMessage
    public required init(model: TSOutgoingMessage) {
        self.model = model
    }

    // MARK: - Record

    func asRecord() throws -> SDSRecord {
        let id: Int64? = nil

        let recordType: SDSRecordType = .outgoingMessage
        let uniqueId: String = model.uniqueId

        // Base class properties
        let receivedAtTimestamp: UInt64 = model.receivedAtTimestamp
        let timestamp: UInt64 = model.timestamp
        let threadUniqueId: String = model.uniqueThreadId

        // Subclass properties
        let attachmentFilenameMap: Data? = optionalArchive(model.attachmentFilenameMap)
        let attachmentIds: Data? = optionalArchive(model.attachmentIds)
        let authorId: String? = nil
        let authorPhoneNumber: String? = nil
        let authorUUID: String? = nil
        let body: String? = model.body
        let callSchemaVersion: UInt? = nil
        let callType: RPRecentCallType? = nil
        let configurationDurationSeconds: UInt32? = nil
        let configurationIsEnabled: Bool? = nil
        let contactId: String? = nil
        let contactShare: Data? = optionalArchive(model.contactShare)
        let createdByRemoteName: String? = nil
        let createdInExistingGroup: Bool? = nil
        let customMessage: String? = model.customMessage
        let envelopeData: Data? = nil
        let errorMessageSchemaVersion: UInt? = nil
        let errorType: TSErrorMessageType? = nil
        let expireStartedAt: UInt64? = model.expireStartedAt
        let expiresAt: UInt64? = model.expiresAt
        let expiresInSeconds: UInt32? = model.expiresInSeconds
        let groupMetaMessage: TSGroupMetaMessage? = model.groupMetaMessage
        let hasLegacyMessageState: Bool? = model.hasLegacyMessageState
        let hasSyncedTranscript: Bool? = model.hasSyncedTranscript
        let incomingMessageSchemaVersion: UInt? = nil
        let infoMessageSchemaVersion: UInt? = nil
        let isFromLinkedDevice: Bool? = model.isFromLinkedDevice
        let isLocalChange: Bool? = nil
        let isViewOnceComplete: Bool? = model.isViewOnceComplete
        let isViewOnceMessage: Bool? = model.isViewOnceMessage
        let isVoiceMessage: Bool? = model.isVoiceMessage
        let legacyMessageState: TSOutgoingMessageState? = model.legacyMessageState
        let legacyWasDelivered: Bool? = model.legacyWasDelivered
        let linkPreview: Data? = optionalArchive(model.linkPreview)
        let messageId: String? = nil
        let messageSticker: Data? = optionalArchive(model.messageSticker)
        let messageType: TSInfoMessageType? = nil
        let mostRecentFailureText: String? = model.mostRecentFailureText
        let outgoingMessageSchemaVersion: UInt? = model.outgoingMessageSchemaVersion
        let preKeyBundle: Data? = nil
        let protocolVersion: UInt? = nil
        let quotedMessage: Data? = optionalArchive(model.quotedMessage)
        let read: Bool? = nil
        let recipientAddress: Data? = nil
        let recipientAddressStates: Data? = optionalArchive(model.recipientAddressStates)
        let schemaVersion: UInt? = model.schemaVersion
        let sender: Data? = nil
        let serverTimestamp: UInt64? = nil
        let sourceDeviceId: UInt32? = nil
        let storedMessageState: TSOutgoingMessageState? = model.storedMessageState
        let storedShouldStartExpireTimer: Bool? = model.storedShouldStartExpireTimer
        let unknownProtocolVersionMessageSchemaVersion: UInt? = nil
        let unregisteredAddress: Data? = nil
        let verificationState: OWSVerificationState? = nil
        let wasReceivedByUD: Bool? = nil

        return InteractionRecord(id: id, recordType: recordType, uniqueId: uniqueId, receivedAtTimestamp: receivedAtTimestamp, timestamp: timestamp, threadUniqueId: threadUniqueId, attachmentFilenameMap: attachmentFilenameMap, attachmentIds: attachmentIds, authorId: authorId, authorPhoneNumber: authorPhoneNumber, authorUUID: authorUUID, body: body, callSchemaVersion: callSchemaVersion, callType: callType, configurationDurationSeconds: configurationDurationSeconds, configurationIsEnabled: configurationIsEnabled, contactId: contactId, contactShare: contactShare, createdByRemoteName: createdByRemoteName, createdInExistingGroup: createdInExistingGroup, customMessage: customMessage, envelopeData: envelopeData, errorMessageSchemaVersion: errorMessageSchemaVersion, errorType: errorType, expireStartedAt: expireStartedAt, expiresAt: expiresAt, expiresInSeconds: expiresInSeconds, groupMetaMessage: groupMetaMessage, hasLegacyMessageState: hasLegacyMessageState, hasSyncedTranscript: hasSyncedTranscript, incomingMessageSchemaVersion: incomingMessageSchemaVersion, infoMessageSchemaVersion: infoMessageSchemaVersion, isFromLinkedDevice: isFromLinkedDevice, isLocalChange: isLocalChange, isViewOnceComplete: isViewOnceComplete, isViewOnceMessage: isViewOnceMessage, isVoiceMessage: isVoiceMessage, legacyMessageState: legacyMessageState, legacyWasDelivered: legacyWasDelivered, linkPreview: linkPreview, messageId: messageId, messageSticker: messageSticker, messageType: messageType, mostRecentFailureText: mostRecentFailureText, outgoingMessageSchemaVersion: outgoingMessageSchemaVersion, preKeyBundle: preKeyBundle, protocolVersion: protocolVersion, quotedMessage: quotedMessage, read: read, recipientAddress: recipientAddress, recipientAddressStates: recipientAddressStates, schemaVersion: schemaVersion, sender: sender, serverTimestamp: serverTimestamp, sourceDeviceId: sourceDeviceId, storedMessageState: storedMessageState, storedShouldStartExpireTimer: storedShouldStartExpireTimer, unknownProtocolVersionMessageSchemaVersion: unknownProtocolVersionMessageSchemaVersion, unregisteredAddress: unregisteredAddress, verificationState: verificationState, wasReceivedByUD: wasReceivedByUD)
    }
}

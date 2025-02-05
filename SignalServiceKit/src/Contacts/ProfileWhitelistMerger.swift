//
// Copyright 2023 Signal Messenger, LLC
// SPDX-License-Identifier: AGPL-3.0-only
//

import Foundation

class ProfileWhitelistMerger: RecipientMergeObserver {
    private let profileManager: ProfileManagerProtocol

    init(profileManager: ProfileManagerProtocol) {
        self.profileManager = profileManager
    }

    func willBreakAssociation(_ recipientAssociation: RecipientAssociation, tx: DBWriteTransaction) {
        let tx = SDSDB.shimOnlyBridge(tx)
        profileManager.normalizeRecipientInProfileWhitelist(recipientAssociation.signalRecipient, tx: tx)
    }

    func didLearnAssociation(mergedRecipient: MergedRecipient, transaction tx: DBWriteTransaction) {
        if mergedRecipient.isLocalRecipient {
            return
        }
        let tx = SDSDB.shimOnlyBridge(tx)
        profileManager.normalizeRecipientInProfileWhitelist(mergedRecipient.signalRecipient, tx: tx)
    }
}

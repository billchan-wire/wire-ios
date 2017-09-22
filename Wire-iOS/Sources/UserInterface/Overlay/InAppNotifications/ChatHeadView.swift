//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
//

import UIKit
import Cartography
import PureLayout

class ChatHeadView: UIView {

    private var userImageView: ContrastUserImageView!
    private var titleLabel: UILabel!
    private var subtitleLabel: UILabel!
    private var labelContainer: UIView!
    
    private let isActiveAccount: Bool
    private let isOneToOneConversation: Bool
    
    private let message: ZMConversationMessage
    private let conversationName: String
    private let senderName: String
    private let teamName: String?
    
    public var onSelect: ((ZMConversationMessage) -> Void)?
    
    override var intrinsicContentSize: CGSize {
        let height = magicFloat("image_diameter") + 2 * magicFloat("content_padding")
        return CGSize(width: UIViewNoIntrinsicMetric, height: height)
    }

    private let magicFloat: (String) -> CGFloat = {
        return WAZUIMagic.cgFloat(forIdentifier: "notifications.\($0)")
    }
    
    private let magicFont: (String) -> UIFont = {
        return UIFont(magicIdentifier: "notifications.\($0)")
    }
    
    init?(notification: UILocalNotification) {
        
        let isSelfAccount: (Account) -> Bool = { return $0.userIdentifier == notification.zm_selfUserUUID }
        
        guard
            let accountManager = SessionManager.shared?.accountManager,
            let account = accountManager.accounts.first(where: isSelfAccount),
            let session = SessionManager.shared?.backgroundUserSessions[account],
            let conversation = notification.conversation(in: session.managedObjectContext),
            let message = notification.message(in: conversation, in: session.managedObjectContext),
            let sender = message.sender
            else {
                return nil
        }
        
        self.message = message
        self.conversationName = conversation.displayName
        self.senderName = sender.displayName
        self.teamName = account.teamName
        self.isActiveAccount = account == accountManager.selectedAccount
        self.isOneToOneConversation = conversation.conversationType == .oneOnOne
        super.init(frame: .zero)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setup() {
        backgroundColor = .white
        layer.cornerRadius = magicFloat("corner_radius")
        layer.borderWidth = 0.5
        layer.borderColor = UIColor(white: 230/255.0, alpha: 1).cgColor
        
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.12
        layer.shadowRadius = 8.0
        layer.shadowOffset = CGSize(width: 0, height: 8)
        layer.masksToBounds = false
        
        createLabels()
        createImageView()
        createConstraints()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapInAppNotification(_:)))
        addGestureRecognizer(tap)
    }
    
    private func createLabels() {
        titleLabel = UILabel()
        subtitleLabel = UILabel()
        labelContainer = UIView()
        addSubview(labelContainer)
        
        [titleLabel, subtitleLabel].forEach {
            labelContainer.addSubview($0!)
            $0!.backgroundColor = .clear
            $0!.isUserInteractionEnabled = false
        }
        
        titleLabel.attributedText = titleText()
        titleLabel.textColor = UIColor(red: 51/255.0, green: 55/255.0, blue: 58/255.0, alpha: 1)
        titleLabel.lineBreakMode = .byTruncatingTail
        
        subtitleLabel.text = subtitleText()
        subtitleLabel.font = messageFont()
        subtitleLabel.textColor = UIColor(white: 153/255.0, alpha: 1)
        subtitleLabel.lineBreakMode = .byTruncatingTail
    }
    
    private func createImageView() {
        userImageView = ContrastUserImageView(magicPrefix: "notifications")
        userImageView.userSession = ZMUserSession.shared()
        userImageView.isUserInteractionEnabled = false
        userImageView.translatesAutoresizingMaskIntoConstraints = false
        userImageView.user = message.sender
        userImageView.accessibilityIdentifier = "ChatheadAvatarImage"
        addSubview(userImageView)
    }
    
    private func createConstraints() {
        
        let imageDiameter = magicFloat("image_diameter")
        let padding = magicFloat("content_padding")
        
        constrain(labelContainer, titleLabel, subtitleLabel) { container, titleLabel, subtitleLabel in
            titleLabel.leading == container.leading
            titleLabel.trailing == container.trailing
            titleLabel.bottom == container.centerY
            
            subtitleLabel.leading == container.leading
            subtitleLabel.top == container.centerY
            subtitleLabel.trailing == container.trailing
        }
        
        constrain(self, userImageView, labelContainer) { selfView, imageView, labelContainer in
            imageView.height == imageDiameter
            imageView.width == imageView.height
            imageView.leading == selfView.leading + padding
            imageView.centerY == selfView.centerY
            
            labelContainer.leading == imageView.trailing + padding
            labelContainer.trailing == selfView.trailing - padding
            labelContainer.height == selfView.height
            labelContainer.centerY == selfView.centerY
        }
    }
    
    // MARK: - Private Helpers
    
    private func titleText() -> NSAttributedString {

        let regularFont: [String: AnyObject] = [NSFontAttributeName: magicFont("title_label_font_regular")]
        let mediumFont: [String: AnyObject] = [NSFontAttributeName: magicFont("title_label_font_medium")]

        if let teamName = teamName, !isActiveAccount {
            let result = NSMutableAttributedString(string: "in ", attributes: regularFont)
            result.append(NSAttributedString(string: teamName, attributes: mediumFont))
            
            if !isOneToOneConversation {
                result.insert(NSAttributedString(string: conversationName + " ", attributes: mediumFont), at: 0)
            }
            
            return result

        } else {
            return NSAttributedString(string: conversationName, attributes: mediumFont)
        }
    }
    
    private func subtitleText() -> String {
        let content = messageText()
        return (isActiveAccount && isOneToOneConversation) ? content : "\(senderName): \(content)"
    }
    
    private func messageText() -> String {
        var result = ""
        
        if Message.isText(message) {
            return (message.textMessageData!.messageText as NSString).resolvingEmoticonShortcuts()
        } else if Message.isImage(message) {
            result = "notifications.shared_a_photo".localized
        } else if Message.isKnock(message) {
            result = "notifications.pinged".localized
        } else if Message.isVideo(message) {
            result = "notifications.sent_video".localized
        } else if Message.isAudio(message) {
            result = "notifications.sent_audio".localized
        } else if Message.isFileTransfer(message) {
            result = "notifications.sent_file".localized
        } else if Message.isLocation(message) {
            result = "notifications.sent_location".localized
        }
        
        return result
    }

    private func messageFont() -> UIFont {
        let font = magicFont("subtitle_label_font")
        if message.isEphemeral {
            return UIFont(name: "RedactedScript-Regular", size: font.pointSize)!
        }
        return font
    }
    
    // MARK: - Actions
    
    @objc private func didTapInAppNotification(_ gestureRecognizer: UITapGestureRecognizer) {
        removeFromSuperview()
        if let onSelect = onSelect, gestureRecognizer.state == .recognized {
            onSelect(message)
        }
    }
}

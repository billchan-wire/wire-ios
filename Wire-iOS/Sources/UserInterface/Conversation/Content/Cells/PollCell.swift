//
//  PollCell.swift
//  Wire-iOS
//
//  Created by Marco Conti on 03/03/2017.
//  Copyright © 2017 Zeta Project Germany GmbH. All rights reserved.
//

import Foundation
import Cartography

@available(iOS 9.0, *)
@objc class PollCell: ConversationCell {
    
    /// Stack view that will contain the individual options
    fileprivate var optionsStackView: UIStackView!
    
    // All icon buttons
    fileprivate var buttons: [IconButton] = []
    
    override func configure(for message: ZMConversationMessage!, layoutProperties: ConversationCellLayoutProperties!) {
        self.resetAll()
        super.configure(for: message, layoutProperties: layoutProperties)
        self.setupStackView()
        guard let poll = message.pollMessageData else { return }
        poll.entries.forEach {
            self.add(option: $0)
        }
    }
}

@available(iOS 9.0, *)
extension PollCell {
    
    /// Sets up the stack view that will
    fileprivate func setupStackView() {
        if self.optionsStackView == nil {
            self.optionsStackView = UIStackView()
            self.optionsStackView.axis = .vertical
            self.messageContentView.addSubview(self.optionsStackView)
            constrain(self.messageContentView, self.optionsStackView ) {
                content, stack in
                stack.bottom == content.bottom
                stack.leading == content.leading
                stack.trailing == content.trailing
                stack.top == content.top
            }
        }
    }
    
    /// Remove all preview views from the stack
    fileprivate func resetAll() {
        guard let stack = self.optionsStackView else { return }
        let allViews = stack.arrangedSubviews
        allViews.forEach {
            stack.removeArrangedSubview($0)
        }
        self.buttons = []
        let views = self.messageContentView.subviews
        views.forEach {
            $0.removeFromSuperview()
        }
        self.optionsStackView = nil
    }
    
    /// Creates the view for an option and add it
    fileprivate func add(option: String) {
        let optionCell = UIView()
        
        let selectButton = IconButton()
        selectButton.setIconColor(.lightGray, for: .normal)
        selectButton.setIcon(.checkmarkCircled, with: .tiny, for: .selected)
        selectButton.setIconColor(.green, for: .selected)
        selectButton.setIcon(.checkmark, with: .small, for: .normal)
        selectButton.setIconColor(.lightGray, for: .normal)
        selectButton.addTarget(self, action: #selector(self.didVoteForOption(_:)), for: .touchUpInside)
        self.buttons.append(selectButton)
        optionCell.addSubview(selectButton)
        
        let label = UILabel()
        label.numberOfLines = 0
        label.text = option
        optionCell.addSubview(label)
        constrain(optionCell, label, selectButton) {
            cell, label, button in
            button.leading == cell.leading + 20.0
            button.trailing == label.leading
            label.trailing == cell.trailing
            button.top == cell.top
            button.bottom == cell.bottom
            label.top == cell.top
            label.bottom == cell.bottom
            button.width == 40.0
            label.height == 35.0
        }
        self.optionsStackView.addArrangedSubview(optionCell)
    }
    
    func didVoteForOption(_ sender: Any) {
        guard let button = sender as? IconButton else { return }
        guard let index = self.buttons.index(of: button) else { return }
        guard let pollData = self.message.pollMessageData else { return }
        self.buttons.forEach {
            $0.isSelected = false
        }
        button.isSelected = true
        ZMUserSession.shared()?.performChanges {
            pollData.castVote(index: index)
        }
    }
}
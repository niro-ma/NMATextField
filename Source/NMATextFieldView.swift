//
//  NMATextFieldView.swift
//  NMATextFieldView
//
//  Created by Niroshan Maheswaran on 02.05.20.
//  Copyright © 2020 Niroshan Maheswaran. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

/// NMATextfield specific colors.
public enum NMATextFieldColors {
    static let warning = #colorLiteral(red: 1, green: 0.2792545518, blue: 0.2245396753, alpha: 1)
    static let dark54 = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.54)
    static let dark38 = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.38)
    static let dark12 = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.12)
    static let darkText = #colorLiteral(red: 0.1294117647, green: 0.1294117647, blue: 0.1294117647, alpha: 1)
}

/// Determines visibility of trailing view..
public enum ViewMode {

    /// Trailing view always visible
    case always

    /// Trailing view never visible
    case never
}

class NMATextFieldView: UIView {

    // MARK: - Outlets

    @IBOutlet var contentView: UIView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var textField: UITextField!
    @IBOutlet private weak var errorLabel: UILabel!
    @IBOutlet private weak var trailingView: UIView!
    @IBOutlet private weak var singleLineBorderView: UIView!
    @IBOutlet private weak var singleLineBorderViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var leadingStackView: UIStackView!
    
    // MARK: - Inspectables
    
    /// Text for textfield placeholder.
    @IBInspectable var placeholderTitle: String? {
        set {
            placeholder = newValue
        }

        get {
            placeholder
        }
    }

    /// Text for title of textfield.
    @IBInspectable var title: String? {
        set {
            titleLabel.text = newValue
            isMandatorySubject.onNext(isMandatory)
        }

        get {
            titleLabel.text
        }
    }

    /// Error message.
    @IBInspectable var error: String? {
        set {
            errorLabel.text = newValue
        }

        get {
            errorLabel.text
        }
    }

    /// Determines if textfield input is mandatory.
    @IBInspectable var isMandatory: Bool = false {
        didSet {
            isMandatorySubject.onNext(isMandatory)
        }
    }
    
    /// Determines whether interaction with textfield is enabled or disabled.
    /// When textfield interaction will be set, there cannot be any other UI objects in the trailing view except the lock image.
    @IBInspectable var textFieldInteractionEnabled: Bool {
        set {
            textField.isUserInteractionEnabled = newValue
            placeholder = textField.placeholder
            trailingView.subviews.forEach { $0.removeFromSuperview() }
            textField.textColor = newValue ? NMATextFieldColors.darkText : NMATextFieldColors.dark38
            titleLabel.textColor = newValue ? NMATextFieldColors.dark54 : NMATextFieldColors.dark38

            if !newValue {
                trailingView.addSubview(lockImageView)
                trailingViewMode = .always
                textField.textColor = .lightGray
            }
        }

        get {
            textField.isUserInteractionEnabled
        }
    }
    
    /// AccessibilityIdentfier for textfield.
    @IBInspectable var accessibilityIdentfier: String? {
        set {
            textField.accessibilityIdentifier = newValue
        }

        get {
            textField.accessibilityIdentifier
        }
    }
    
    /// Color of textfield text.
    @IBInspectable var textColor: UIColor? {
        set {
            textField.textColor = newValue
        }

        get {
            textfield.textColor
        }
    }
    
    /// Color textfields cursor.
    @IBInspectable var cursorColor: UIColor? {
        set {
            textField.tintColor = newValue
        }

        get {
            textfield.tintColor
        }
    }
    
    /// Color of textfield when editing begins.
    @IBInspectable var focusColor: UIColor?
    
    // MARK: - Public Properties

    /// Textfield.
    public var textfield: UITextField {
        textField
    }
    
    /// Textfield font.
    public var textFont: UIFont? {
        set {
            textfield.font = newValue
        }
        
        get {
            textfield.font
        }
    }
    
    /// Title font.
    public var titleFont: UIFont? {
        set {
            titleLabel.font = newValue
        }
        
        get {
            titleLabel.font
        }
    }
    
    /// Error font.
    public var errorFont: UIFont? {
        set {
            errorLabel.font = newValue
        }
        
        get {
            errorLabel.font
        }
    }

    /// Mode for trailing view.
    public var trailingViewMode: ViewMode {
        set {
            trailingView.isHidden = newValue == .never
        }

        get {
            trailingView.isHidden ? .never : .always
        }
    }

    /// Reactive way to bind text to textfield.
    public var reactiveText = PublishSubject<String?>()

    /// Textfield text.
    public var text: String? {
        set {
            textField.text = newValue
            validateInput(newValue)
        }

        get {
            textField.text
        }
    }

    /// True for secured text entry.
    public var isSecured: Bool {
        set {

            if !trailingView.subviews.contains(where: {
                let buttonImageData = ($0 as? UIButton)?.imageView?.image?.pngData()
                return buttonImageData  == #imageLiteral(resourceName: "iconsViewOn").pngData() || buttonImageData == #imageLiteral(resourceName: "iconsViewOff").pngData()
            }) {
                showPasswordVisibleTrailingView()
            }

            textField.isSecureTextEntry = newValue

            guard let button = trailingView.subviews.first(where: {
                let buttonImageData = ($0 as? UIButton)?.imageView?.image?.pngData()
                return buttonImageData  == #imageLiteral(resourceName: "iconsViewOn").pngData() || buttonImageData == #imageLiteral(resourceName: "iconsViewOff").pngData()
            }) as? UIButton else { return }

            newValue
                ? button.setImage(#imageLiteral(resourceName: "iconsViewOff"), for: .normal)
                : button.setImage(#imageLiteral(resourceName: "iconsViewOn"), for: .normal)
        }

        get {
            textField.isSecureTextEntry
        }
    }

    /// Textfield placeholder
    public var placeholder: String? {
        didSet {
            guard let placeholder = placeholder else { return }
            textField.attributedPlaceholder = NSAttributedString(
                string: placeholder,
                attributes: placeholderAttributes
            )
        }
    }

    /// Delegate of textfield.
    public weak var delegate: UITextFieldDelegate? {
        didSet {
            textField.delegate = self.delegate
        }
    }

    /// Keyboard type for textfield.
    public var keyboardType: UIKeyboardType = .default {
        didSet {
            textField.keyboardType = self.keyboardType
        }
    }

    /// Emits true when entry of textfield is valid.
    /// The validation only checks if textfield is empty.
    /// If any regex should be checked then a seperate validation in the corresponding ViewModel is needed.
    public var isValidDriver: Driver<Bool> {
        isValidSubject.asDriver(onErrorJustReturn: false)
    }

    /// Non-reactive identifier if entry of mandatory textfield is valid.
    private(set) var isValid: Bool = false
    
    /// Maximum number of characters for this textfield. Default is 255.
    public var maxLength: Int = LengthTypes.standard

    // MARK: - Private computed properties

    private var errorImageView: UIImageView {
        let errorIcon = #imageLiteral(resourceName: "iconsAlert")
        let errorImageView = UIImageView(image: errorIcon)
        errorImageView.tintColor = NMATextFieldColors.warning
        errorImageView.frame.size = trailingView.frame.size
        return errorImageView
    }
    private var lockImageView: UIImageView {
        let lockIcon = #imageLiteral(resourceName: "iconsLock")
        let lockImageView = UIImageView(image: lockIcon)
        lockImageView.tintColor = NMATextFieldColors.dark38
        lockImageView.frame.size = trailingView.frame.size
        return lockImageView
    }
    private var passwordVisibilityButton: UIButton {
        let eyeIcon = #imageLiteral(resourceName: "iconsViewOn")
        let eyeVisibilityButton = UIButton(frame: CGRect(origin: .zero, size: trailingView.frame.size))
        eyeVisibilityButton.setImage(eyeIcon, for: .normal)
        eyeVisibilityButton.tintColor = NMATextFieldColors.dark38
        eyeVisibilityButton.addTarget(self, action: #selector(passwordVisibilityButtonTapped), for: .touchUpInside)
        return eyeVisibilityButton
    }

    // MARK: - Private properties

    /// Emits when isMandatory property was set.
    private var isMandatorySubject = PublishSubject<Bool>()
    private var isValidSubject = PublishSubject<Bool>()
    private var disposeBag = DisposeBag()

    /// Identifier to check if this textfield was already focused.
    /// If true validation will be performed every time the textfield turns into editing mode.
    private var focusedAlready: Bool = false

    // MARK: - Public methods

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    /// Shows error.
    public func showError(errorMessage: String? = nil) {
        if let message = errorMessage {
            errorLabel.text = message
        }
        errorLabel.isHidden = false
        singleLineBorderView.backgroundColor = NMATextFieldColors.warning
        titleLabel.textColor = NMATextFieldColors.warning

        /// If input field is secured then the info i icon should not be visible while showing error.
        if !trailingView.subviews.contains(where: {
            let buttonImageData = ($0 as? UIButton)?.imageView?.image?.pngData()
            return buttonImageData == #imageLiteral(resourceName: "iconsViewOn").pngData() || buttonImageData == #imageLiteral(resourceName: "iconsViewOff").pngData()
        }) {
            trailingView.subviews.forEach { $0.isHidden = true }
            trailingView.addSubview(errorImageView)
            trailingViewMode = .always
        }
        
    }

    /// Hides errror.
    public func hideError() {
        errorLabel.isHidden = true
        singleLineBorderView.backgroundColor = focusColor
        titleLabel.textColor = NMATextFieldColors.dark54

        trailingView.subviews.forEach {
            if ($0 as? UIImageView)?.image?.pngData() == errorImageView.image?.pngData() {
                $0.removeFromSuperview()
            }

            $0.isHidden = false
        }
        trailingViewMode = trailingView.subviews.isEmpty ? .never : .always
        self.layoutSubviews()
    }

    /// Sets trailing view.
    /// - Parameter view: Trailing view.
    public func setTrailingView(_ view: UIView) {
        view.frame.origin = CGPoint(x: 0, y: 0)
        view.frame.size = trailingView.frame.size
        self.trailingView.addSubview(view)
        trailingViewMode = .always
    }

    /// Compares if given textfield is equal to textfield of this view.
    /// - Parameter textfield: Textfield that needs to be compared.
    public func `is`(_ textfield: UITextField) -> Bool {
        return self.textField == textfield
    }

    /// Clears textfield input.
    public func reset() {
        self.isValidSubject.onNext(false)
        text = ""
        hideError()
    }

    /// Since this view contains the textfield this method
    /// is equivalent to becomeFirstResponder of UITextField.
    public func becomeResponder() -> Bool {
        textField.becomeFirstResponder()
    }

    /// Since this view contains the textfield this method
    /// is equivalent to resignFirstResponder of UITextField.
    public func resignResponder() -> Bool {
        textField.resignFirstResponder()
    }
}

// MARK: - Private methods

/// Extension to encapsulate private methods.
extension NMATextFieldView {

    /// Validates input of textfield if it's mandatory.
    private func validateInput(_ text: String?) {
        guard self.isMandatory else { return }
        guard let text = text else {
            self.isValidSubject.onNext(false)
            return
        }
        isValidSubject.onNext(!text.isEmpty)
    }

    /// Simple validation to check if textfield is empty.
    private func subscribeTextfieldValidation() {
        reactiveText
            .subscribe(onNext: { [unowned self] text in
                self.textfield.text = text
                self.validateInput(text)
            })
            .disposed(by: disposeBag)

        textfield
            .rx
            .text
            .distinctUntilChanged()
            .skip(1)
            .debounce(.milliseconds(500), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [unowned self] text in
                self.validateInput(text)
            })
            .disposed(by: disposeBag)

        isValidSubject
            .subscribe(onNext: { [unowned self] valid in
                self.isValid = valid
                valid ? self.hideError() : self.showError()
            })
            .disposed(by: disposeBag)
    }
    
    /// An RX subscription to the textfield text to limit the number of characters.
    private func characterLimitSubscription() {
        textfield
            .rx
            .text
            .orEmpty
            .map { [unowned self] in
                $0.count > self.maxLength
            }
            .share(replay: 1)
            .subscribe(onNext: { [unowned self] limitExceeded in
                guard let text = self.textfield.text else { return }
                if limitExceeded {
                    let allowedTextIndex = text.index(
                        text.startIndex,
                        offsetBy: self.maxLength
                    )
                    self.textfield.text = String(text[..<allowedTextIndex])
                    self.textField.selectedTextRange = self.textField.textRange(
                        from: self.textField.endOfDocument,
                        to: self.textField.endOfDocument
                    )
                }
            })
            .disposed(by: disposeBag)
    }

    private func subscribeTextFieldControlEvents() {
        textField
            .rx
            .controlEvent(.editingDidBegin)
            .map { true }
            .subscribe(onNext: { [unowned self] in
                self.textFieldFocused($0)
            })
            .disposed(by: disposeBag)

        textField
            .rx
            .controlEvent(.editingDidEnd)
            .map { false }
            .subscribe(onNext: { [unowned self] in
                self.validateInput(self.text)
                self.textFieldFocused($0)
            })
            .disposed(by: disposeBag)
    }

    /// Common init.
    private func commonInit() {
        let nib = UINib(nibName: String(describing: NMATextFieldView.self), bundle: nil)
        nib.instantiate(withOwner: self, options: nil)
        contentView.frame = bounds
        textfield.accessibilityIdentifier = self.accessibilityIdentifier
        self.accessibilityIdentifier = ""
        addSubview(contentView)

        errorLabel.isHidden = true

        isMandatorySubject
            .subscribe(onNext: { [unowned self] mandatory in
                guard let localizedTitle = self.title else { return }
                self.titleLabel.text = mandatory
                    ? localizedTitle + "*"
                    : localizedTitle
            })
            .disposed(by: disposeBag)

        subscribeTextFieldControlEvents()
        characterLimitSubscription()
        subscribeTextfieldValidation()
    }
    
    private var placeholderAttributes: [NSAttributedString.Key: NSObject] {
        return [
            NSAttributedString.Key.foregroundColor: textField.isUserInteractionEnabled
                ? NMATextFieldColors.dark54
                : NMATextFieldColors.dark38
        ]
    }

    private func textFieldFocused(_ focused: Bool) {
        if focused {
            hideError()
        }
        singleLineBorderView.backgroundColor = focused
            ? focusColor
            : errorLabel.isHidden ? NMATextFieldColors.dark12 : NMATextFieldColors.warning
        singleLineBorderViewHeightConstraint.constant = focused ? 2 : 1
    }

    private func showPasswordVisibleTrailingView() {
        trailingView.subviews.forEach { $0.isHidden = true }
        trailingView.addSubview(passwordVisibilityButton)
        trailingViewMode = .always
    }

    @objc private func passwordVisibilityButtonTapped() {
        isSecured = !textField.isSecureTextEntry
    }
}

/// Extension on NMATextFieldView.
extension NMATextFieldView {

    /// Returns max number of characters to corresponding type.
    public enum LengthTypes {
        /// Default length.
        static let standard = 255
    }
}

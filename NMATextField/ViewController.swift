//
//  ViewController.swift
//  NMATextField
//
//  Created by Niroshan Maheswaran on 03.05.21.
//

import UIKit

class ViewController: UIViewController, KeyboardHandler {

    // MARK: - Outlets
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var securedTextField: NMATextFieldView!
    @IBOutlet weak var notEditableTextField: NMATextFieldView!
    @IBOutlet weak var mandatoryTextField: NMATextFieldView!
    @IBOutlet weak var numberTextField: NMANumericTextFieldView!
    @IBOutlet weak var limitedTextField: NMATextFieldView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        subscribeKeyboard(with: scrollView)
        
        securedTextField.isSecured = true
        notEditableTextField.textFieldInteractionEnabled = false
        notEditableTextField.text = "Text is not editable!"
        limitedTextField.maxLength = 10
    }
}


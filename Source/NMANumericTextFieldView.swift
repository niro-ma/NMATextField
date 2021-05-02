//
//  NMANumericTextFieldView.swift
//  NMATextFieldView
//
//  Created by Niroshan Maheswaran on 02.05.20.
//  Copyright © 2020 Niroshan Maheswaran. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

class NMANumericTextFieldView: NMATextFieldView {

    // MARK: - Private properties

    private let disposeBag = DisposeBag()

    // MARK: - Public methods

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        maxLength = 19

        // This prevents any copy & paste action of negative values.
        self.textfield
            .rx
            .text
            .asDriver(onErrorJustReturn: "")
            .drive(onNext: { [unowned self] text in
                self.textfield.text = text
            })
            .disposed(by: disposeBag)

        self.keyboardType = .numberPad
    }
}

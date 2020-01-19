/*
 Copyright 2016-present The Material Motion Authors. All Rights Reserved.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import Foundation
import UIKit
import MaterialMotion

class StickerPickerExampleViewController: ExampleViewController, StickerListViewControllerDelegate {

  var runtime: MotionRuntime!

  override func viewDidLoad() {
    super.viewDidLoad()

    navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(didTapAdd))

    runtime = MotionRuntime(containerView: view)
  }

  fileprivate func didPickSticker(_ sticker: Sticker) {
    let stickerView = UIView(frame: .init(x: 0, y: 0, width: 100, height: 100))
    stickerView.backgroundColor = sticker.color
    stickerView.center = .init(x: view.bounds.midX, y: view.bounds.midY)
    view.addSubview(stickerView)

    let direction = createProperty(withInitialValue: TransitionDirection.forward)
    let spring = TransitionSpring(back: CGFloat(1.5), fore: 1, direction: direction)
    runtime.add(spring, to: runtime.get(stickerView.layer).scale)

    runtime.add(DirectlyManipulable(), to: stickerView)
  }

    @objc func didTapAdd() {
    let picker = StickerListViewController()
    picker.delegate = self
    present(picker, animated: true)
  }

  override func exampleInformation() -> ExampleInfo {
    return .init(title: type(of: self).catalogBreadcrumbs().last!,
                 instructions: "Tap the plus to add a sticker.")
  }
}

private let numberOfStickers = 3

private struct Sticker {
  let color: UIColor
  let uuid: String

  fileprivate init(color: UIColor) {
    self.color = color

    self.uuid = NSUUID().uuidString
  }
}

private class StickerAlbum {
  let stickers = [
    Sticker(color: .white),
    Sticker(color: .primaryColor),
    Sticker(color: .secondaryColor)
  ]
}

private class StickerCollectionViewCell: UICollectionViewCell {
  let imageView = UIImageView()

  override init(frame: CGRect) {
    super.init(frame: frame)

    imageView.contentMode = .scaleAspectFill
    imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    imageView.frame = bounds
    imageView.clipsToBounds = true

    contentView.addSubview(imageView)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func imageViewForTransition() -> UIImageView {
    return imageView
  }
}

private class StickerListViewController: UICollectionViewController {

  let album = StickerAlbum()
  var selectedSticker: Sticker?
  weak var delegate: StickerListViewControllerDelegate?

  init() {
    super.init(collectionViewLayout: UICollectionViewFlowLayout())

    transitionController.transition = ModalTransition()

    modalPresentationStyle = .overCurrentContext
  }

  public required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override public func viewDidLoad() {
    super.viewDidLoad()

    collectionView!.backgroundColor = UIColor(white: 0, alpha: 0.25)
    collectionView!.register(StickerViewCell.self,
                             forCellWithReuseIdentifier: stickerCellIdentifier)
  }

  public override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()

    updateLayout()
  }

  func updateLayout() {
    let layout = collectionView!.collectionViewLayout as! UICollectionViewFlowLayout
    layout.sectionInset = .init(top: 4, left: 4, bottom: 4, right: 4)
    layout.minimumInteritemSpacing = 4
    layout.minimumLineSpacing = 4
    layout.headerReferenceSize = .init(width: 0, height: 48)

    let numberOfColumns: CGFloat = 3
    let squareDimension = (view.bounds.width - layout.sectionInset.left - layout.sectionInset.right - (numberOfColumns - 1) * layout.minimumInteritemSpacing) / numberOfColumns
    layout.itemSize = CGSize(width: squareDimension, height: squareDimension)
  }

  public override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return album.stickers.count
  }

  public override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: stickerCellIdentifier,
                                                  for: indexPath) as! StickerViewCell
    let sticker = album.stickers[indexPath.row]
    cell.view.backgroundColor = sticker.color
    return cell
  }

  public override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    selectedSticker = album.stickers[indexPath.row]
    delegate?.didPickSticker(selectedSticker!)
    dismiss(animated: true)
  }
}

let stickerCellIdentifier = "stickerCell"

private class StickerViewCell: UICollectionViewCell {
  let view = UIView()

  override init(frame: CGRect) {
    super.init(frame: frame)

    view.frame = bounds.insetBy(dx: 8, dy: 8)

    contentView.addSubview(view)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func layoutSubviews() {
    super.layoutSubviews()

    view.frame = bounds.insetBy(dx: 8, dy: 8)
  }
}

private protocol StickerListViewControllerDelegate: NSObjectProtocol {
  func didPickSticker(_ sticker: Sticker)
}

private class ModalTransition: Transition {

  required init() {}

  func willBeginTransition(withContext ctx: TransitionContext, runtime: MotionRuntime) -> [Stateful] {
    let size = ctx.fore.preferredContentSize == .zero() ? ctx.fore.view.bounds.size : ctx.fore.preferredContentSize

    if ctx.direction == .forward {
      ctx.fore.view.bounds = CGRect(origin: .zero, size: size)
    }

    let spring = TransitionSpring<CGFloat>(back: 0, fore: 1, direction: ctx.direction)
    runtime.add(spring, to: runtime.get(ctx.fore.view.layer).opacity)

    return [spring]
  }
}

![Former](https://raw.githubusercontent.com/ra1028/Former/master/Logo.png)

#### Former is a fully customizable Swift library for easy creating UITableView based form.
[![Swift3](https://img.shields.io/badge/swift3-compatible-4BC51D.svg?style=flat)](https://developer.apple.com/swift)
[![CocoaPods Shield](https://img.shields.io/cocoapods/v/Former.svg)](https://cocoapods.org/pods/Former)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![MIT License](http://img.shields.io/badge/license-MIT-green.svg?style=flat)](https://raw.githubusercontent.com/ra1028/Former/master/LICENSE)

## Maintainers Wanted
I'm losing `Former` development willingness now.  
If you are willing to develop in place of me, please feel free to contact me.  
I'll grant you authority associated with `Former` development.  

## Demo
<img src="http://i.imgur.com/1gOwZZN.gif" width="220">
<img src="http://i.imgur.com/g9yeTtV.gif" width="220">
<img src="http://i.imgur.com/ouM1SsG.gif" width="220">

## Contents
* [Requirements](#Requirements)
* [Installation](#installation)
* [Usage](#usage)
  + [Simple Example](#simple-example)
  + [RowFormer](#rowformer)
  + [ViewFormer](#viewformer)
  + [SectionFormer](#sectionformer)
  + [Former](#former)
  + [Customizability](#customizability)
* [Contributing](#contributing)
* [Submitting Issues](#submitting-issues)
* [License](#license)

## Requirements  
- Xcode 8
- Swift 3
- iOS 8.0 or later

_Still wanna use iOS7 and swift 2.2 or 2.3?_  
-> You can use [1.4.0](https://github.com/ra1028/Former/tree/1.4.0) instead.  

## Installation
#### [CocoaPods](https://cocoapods.org/)
Add the following line to your Podfile:
```ruby
use_frameworks!

target 'YOUR_TARGET_NAME' do

  pod 'Former'
  
end
```
#### [Carthage](https://github.com/Carthage/Carthage)
Add the following line to your Cartfile:
```ruby
github "ra1028/Former"
```

## Usage
You can set the cell's appearance and events-callback at the same time.  
ViewController and Cell do not need to override the provided defaults. 

### Simple Example
```Swift
import Former

final class ViewController: FormViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let labelRow = LabelRowFormer<FormLabelCell>()
            .configure { row in
                row.text = "Label Cell"
            }.onSelected { row in
                // Do Something
        }
        let inlinePickerRow = InlinePickerRowFormer<FormInlinePickerCell, Int>() {
            $0.titleLabel.text = "Inline Picker Cell"
            }.configure { row in
                row.pickerItems = (1...5).map {
                    InlinePickerItem(title: "Option\($0)", value: Int($0))
                }
            }.onValueChanged { item in
                // Do Something
        }
        let header = LabelViewFormer<FormLabelHeaderView>() { view in
            view.titleLabel.text = "Label Header"
        }
        let section = SectionFormer(rowFormer: labelRow, inlinePickerRow)
            .set(headerViewFormer: header)
        former.append(sectionFormer: section)
    }
}
```


### RowFormer
RowFormer is the base class of the class that manages the cell.
A cell that is managed by the RowFormer class should conform to the corresponding protocol.
Each of the RowFormer classes exposes event handling in functions named "on*" (e.g., onSelected, onValueChanged, etc...)  
Default provided RowFormer classes and the protocols that corresponding to it are listed below.  

<table>
<thead>
<tr>
<th>Demo</th>
<th>Class</th>
<th>Protocol</th>
<th>Default provided cell</th>
</tr>
</thead>

<tbody>
<tr>
<td>Free</td>
<td>CustomRowFormer</td>
<td>None</td>
<td>None</td>
</tr>
<tr>
<td><img src="http://i.imgur.com/ZTzZAG3.gif" width="200"></td>
<td>LabelRowFormer</td>
<td>LabelFormableRow</td>
<td>FormLabelCell</td>
</tr>
<tr>
<td><img src="http://i.imgur.com/sLfvbRz.gif" width="200"></td>
<td>TextFieldRowFormer</td>
<td>TextFieldFormableRow</td>
<td>FormTextFieldCell</td>
</tr>
<tr>
<td><img src="http://i.imgur.com/Es7JOYk.gif" width="200"></td>
<td>TextViewRowFormer</td>
<td>TextViewFormableRow</td>
<td>FormTextViewCell</td>
</tr>
<tr>
<td><img src="http://i.imgur.com/FjrTL51.gif" width="200"></td>
<td>CheckRowFormer</td>
<td>CheckFormableRow</td>
<td>FormCheckCell</td>
</tr>
<tr>
<td><img src="http://i.imgur.com/AfidFhs.gif" width="200"></td>
<td>SwitchRowFormer</td>
<td>SwitchFormableRow</td>
<td>FormSwitchCell</td>
</tr>
<tr>
<td><img src="http://i.imgur.com/ACeA4uq.gif" width="200"></td>
<td>StepperRowFormer</td>
<td>StepperFormableRow</td>
<td>FormStepperCell</td>
</tr>
<tr>
<td><img src="http://i.imgur.com/0KAJK6v.gif" width="200"></td>
<td>SegmentedRowFormer</td>
<td>SegmentedFormableRow</td>
<td>FormSegmentedCell</td>
</tr>
<tr>
<td><img src="http://i.imgur.com/i2ibb0P.gif" width="200"></td>
<td>SliderRowFormer</td>
<td>SliderFormableRow</td>
<td>FormSliderCell</td>
</tr>
<tr>
<td><img src="http://i.imgur.com/Vkfxf2P.gif" width="200"></td>
<td>PickerRowFormer</td>
<td>PickerFormableRow</td>
<td>FormPickerCell</td>
</tr>
<tr>
<td><img src="http://i.imgur.com/MLHG4oP.gif" width="200"></td>
<td>DatePickerRowFormer</td>
<td>DatePickerFormableRow</td>
<td>FormDatePickerCell</td>
</tr>
<tr>
<td><img src="http://i.imgur.com/jUn8Get.gif" width="200"></td>
<td>SelectorPickerRowFormer</td>
<td>SelectorPickerFormableRow</td>
<td>FormSelectorPickerCell</td>
</tr>
<tr>
<td><img src="http://i.imgur.com/VfxaKoL.gif" width="200"></td>
<td>SelectorDatePickerRowFormer</td>
<td>SelectorDatePickerFormableRow</td>
<td>FormSelectorDatePickerCell</td>
</tr>
<tr>
<td><img src="http://i.imgur.com/NHb6SXy.gif" width="200"></td>
<td>InlinePickerRowFormer</td>
<td>InlinePickerFormableRow</td>
<td>FormInlinePickerCell</td>
</tr>
<tr>
<td><img src="http://i.imgur.com/g0M2U4T.gif" width="200"></td>
<td>InlineDatePickerRowFormer</td>
<td>InlineDatePickerFormableRow</td>
<td>FormInlineDatePickerCell</td>
</tr>
</tbody>
</table>

__example with LabelRowFormer__  
```Swift
let labelRow = LabelRowFormer<YourLabelCell>(instantiateType: .Nib(nibName: "YourLabelCell")) {
    $0.titleLabel.textColor = .blackColor()
    }.configure { row in
        row.rowHeight = 44
        row.text = "Label Cell"
    }.onSelected { row in
        print("\(row.text) Selected !!")
}
```
__update the cell__
```Swift
row.update()
row.update { row in
    row.text = "Updated title"
}
row.cellUpdate { cell in
    cell.titleLabel.textColor = .redColor()
}
```
__get cell instance__
```Swift
let cell = row.cell
print(cell.titleLabel.text)
```
__set dynamic row height__
```Swift
row.dynamicRowHeight { tableView, indexPath -> CGFloat in
    return 100
}
```


### ViewFormer
ViewFormer is base class of the class that manages the HeaderFooterView.  
A HeaderFooterView that is managed by the ViewFormer class should conform to the corresponding protocol.
Default provided ViewFormer classes and the protocols that correspond to it are listed below.  

<table>
<thead>
<tr>
<th>Demo</th>
<th>Class</th>
<th>Protocol</th>
<th>Default provided cell</th>
</tr>
</thead>

<tbody>
<tr>
<td>Free</td>
<td>CustomViewFormer</td>
<td>None</td>
<td>None</td>
</tr>
<tr>
<td><img src="http://i.imgur.com/Vmmk0dc.png" width="200"></td>
<td>LabelViewFormer</td>
<td>LabelFormableView</td>
<td>
FormLabelHeaderView  
FormLabelFooterView
</td>
</tr>
</tbody>
</table>

__example with LabelViewFormer__
```Swift
let headerView = LabelViewFormer<YourLabelView>(instantiateType: .Nib(nibName: "YourLabelView")) {
    $0.titleLabel.textColor = .blackColor()
    }.configure { view in
        view.viewHeight = 30
        view.text = "Label HeaderFooter View"
}
```


### SectionFormer
SectionFormer is a class that represents the Section of TableView.  
SectionFormer can append, add, insert, remove the RowFormer and set the ViewFormer.  
__example__  
```Swift
let section = SectionFormer(rowFormer: row1, row2, row3)
    .set(headerViewFormer: headerView)
    .set(footerViewFormer: footerView)
```
__add the cell__
```
section.append(rowFormer: row1, row2, row3)
section.add(rowFormers: rows)
section.insert(rowFormer: row, toIndex: 3)
section.insert(rowFormer: row, below: otherRow)
// etc...
```
__remove the cell__
```Swift
section.remove(0)
section.remove(0...5)
section.remove(rowFormer: row)
// etc...
```
__set the HeaderFooterViewe__
```Swift
section.set(headerViewFormer: headerView)
section.set(footerViewFormer: footerView)
```


### Former
Former is a class that manages the entire form.  
Examples is below.  
__add the section or cell__
```Swift
former.append(sectionFormer: row)
former.add(sectionFormers: rows)
former.insert(sectionFormer: section, toSection: 0)
former.insert(rowFormer: row, toIndexPath: indexPath)
former.insert(sectionFormer: section, above: otherSection)
former.insert(rowFormers: row, below: otherRow)
// etc...

// with animation
former.insertUpdate(sectionFormer: section, toSection: 0, rowAnimation: .Automatic)
former.insertUpdate(rowFormer: row, toIndexPath: indexPath, rowAnimation: .Left)
former.insertUpdate(sectionFormer: section, below: otherSection, rowAnimation: .Fade)
former.insertUpdate(rowFormers: rows, above: otherRow, rowAnimation: .Bottom)
// etc...
```
__remove the section or cell__
```Swift
former.removeAll()
former.remove(rowFormer: row1, row2)
former.remove(sectionFormer: section1, section2)
// etc...

// with animation
former.removeAllUpdate(.Fade)
former.removeUpdate(sectionFormers: sections, rowAnimation: .Middle)
// etc...
```
__Select and deselect the cell__
```Swift
former.select(indexPath: indexPath, animated: true, scrollPosition: .Middle)
former.select(rowFormer: row, animated: true)
former.deselect(true)
// etc...
```
__end editing__
```Swift
former.endEditing()
```
__become editing next/previous cell__
```Swift
if former.canBecomeEditingNext() {
    former.becomeEditingNext()
}
if former.canBecomeEditingPrevious() {
    former.becomeEditingPrevious()
}
```
__functions to setting event handling__
```Swift
public func onCellSelected(handler: (NSIndexPath -> Void)) -> Self
public func onScroll(handler: ((scrollView: UIScrollView) -> Void)) -> Self    
public func onBeginDragging(handler: (UIScrollView -> Void)) -> Self
public func willDeselectCell(handler: (NSIndexPath -> NSIndexPath?)) -> Self
public func willDisplayCell(handler: (NSIndexPath -> Void)) -> Self
public func willDisplayHeader(handler: (/*section:*/Int -> Void)) -> Self
public func willDisplayFooter(handler: (/*section:*/Int -> Void)) -> Self        
public func didDeselectCell(handler: (NSIndexPath -> Void)) -> Self
public func didEndDisplayingCell(handler: (NSIndexPath -> Void)) -> Self
public func didEndDisplayingHeader(handler: (/*section:*/Int -> Void)) -> Self
public func didEndDisplayingFooter(handler: (/*section:*/Int -> Void)) -> Self
public func didHighlightCell(handler: (NSIndexPath -> Void)) -> Self
public func didUnHighlightCell(handler: (NSIndexPath -> Void)) -> Self
```


### Customizability
__ViewController__  
There is no need to inherit from the FormViewController class.  
Instead, create an instance of UITableView and Former, as in the following example.
```Swift
final class YourViewController: UIViewController {    

    private let tableView: UITableView = UITableView(frame: CGRect.zero, style: .Grouped) // It may be IBOutlet. Not forget to addSubview.
    private lazy var former: Former = Former(tableView: self.tableView)

    ...
```
__Cell__
There is likewise no need to inherit from the default provided cell class (FormLabelCell etc ...); only conform to the corresponding protocol.
You can use Nibs, of course.
An example with LabelRowFormer:
```Swift
final class YourCell: UITableViewCell, LabelFormableRow {

    // MARK: LabelFormableRow

    func formTextLabel() -> UILabel? {
        return titleLabel
    }

    func formSubTextLabel() -> UILabel? {
        return subTitleLabel
    }

    func updateWithRowFormer(rowFormer: RowFormer) {
        // Do something
    }

    // MARK: UITableViewCell

    var titleLabel: UILabel?
    var subTitleLabel: UILabel?

    ...
```
__RowFormer__
If you want to create a custom RowFormer, make your class inherit from BaseRowFormer and comply with the Formable protocol.  
It must conform to ConfigurableInlineForm. In the case of InlineRowFomer, conform to the UpdatableSelectorForm case of SelectorRowFormer.
Please look at the source code for details.  
Examples of RowFormer using cells with two UITextFields:  
```Swift
public protocol DoubleTextFieldFormableRow: FormableRow {

    func formTextField1() -> UITextField
    func formTextField2() -> UITextField
}

public final class DoubleTextFieldRowFormer<T: UITableViewCell where T: DoubleTextFieldFormableRow>
: BaseRowFormer<T>, Formable {

    // MARK: Public

    override public var canBecomeEditing: Bool {
        return enabled
    }

    public var text1: String?
    public var text2: String?

    public required init(instantiateType: Former.InstantiateType = .Class, cellSetup: (T -> Void)? = nil) {
        super.init(instantiateType: instantiateType, cellSetup: cellSetup)
    }

    public final func onText1Changed(handler: (String -> Void)) -> Self {
        onText1Changed = handler
        return self
    }

    public final func onText2Changed(handler: (String -> Void)) -> Self {
        onText2Changed = handler
        return self
    }

    open override func cellInitialized(cell: T) {
        super.cellInitialized(cell)
        cell.formTextField1().addTarget(self, action: "text1Changed:", forControlEvents: .EditingChanged)
        cell.formTextField2().addTarget(self, action: "text2Changed:", forControlEvents: .EditingChanged)
    }

    open override func update() {
        super.update()

        cell.selectionStyle = .None
        let textField1 = cell.formTextField1()
        let textField2 = cell.formTextField2()
        textField1.text = text1
        textField2.text = text2        
    }

    // MARK: Private

    private final var onText1Changed: (String -> Void)?
    private final var onText2Changed: (String -> Void)?    

    private dynamic func text1Changed(textField: UITextField) {
        if enabled {
            let text = textField.text ?? ""
            self.text1 = text
            onText1Changed?(text)
        }
    }

    private dynamic func text2Changed(textField: UITextField) {
        if enabled {
            let text = textField.text ?? ""
            self.text2 = text
            onText2Changed?(text)
        }
    }
}
```

## Contributing
If you're interesting in helping us improve and maintain Former, it is highly encouraged that you fork the repository and submit a pull request with your updates.

If you do chose to submit a pull request, please make sure to clearly document what changes you have made in the description of the PR. 

## Submitting Issues
If you find yourself having any issues with Former, feel free to submit an issue. Please BE SURE to include the following:

* TITLE
* ISSUE DESCRIPTION
* HOW TO REPLICATE ISSUE

If your issue doesn't contain this information, it will be closed due to lack of information.

## License
Former is available under the MIT license. See the LICENSE file for more info.

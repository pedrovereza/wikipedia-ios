import UIKit

public enum ReadingListsDisplayType {
    case readingListsTab, addArticlesToReadingList
}

public class ReadingListsCollectionViewCell: ArticleCollectionViewCell {
    private var bottomSeparator = UIView()
    private var topSeparator = UIView()
    
    private var articleCountLabel = UILabel()
    var articleCount: Int64 = 0
    
    private let imageGrid = UIView()
    private var gridImageViews: [UIImageView] = []
    
    private var isDefault: Bool = false
    private let defaultListTag = UILabel() // explains that the default list cannot be deleted
    
    private var singlePixelDimension: CGFloat = 0.5
    
    private var displayType: ReadingListsDisplayType = .readingListsTab
    
    override public var alertType: ReadingListAlertType? {
        didSet {
            guard let alertType = alertType else {
                return
            }
            var alertLabelText: String? = nil
            switch alertType {
            case .listLimitExceeded:
                alertLabelText = WMFLocalizedString("reading-lists-list-not-synced-limit-exceeded", value: "List not synced, limit exceeded", comment: "Text of the alert label informing the user that list couldn't be synced.")
            case .entryLimitExceeded:
                alertLabelText = WMFLocalizedString("reading-lists-articles-not-synced-limit-exceeded", value: "Some articles not synced, limit exceeded", comment: "Text of the alert label informing the user that some articles couldn't be synced.")
            default:
                break
            }
            alertLabel.text = alertLabelText
            
            if !isAlertIconHidden {
                alertIcon.image = UIImage(named: "error-icon")
            }
        }
    }
    
    override public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        singlePixelDimension = traitCollection.displayScale > 0 ? 1.0 / traitCollection.displayScale : 0.5
    }
    
    override public func setup() {
        imageView.layer.cornerRadius = 3
        
        bottomSeparator.isOpaque = true
        contentView.addSubview(bottomSeparator)
        topSeparator.isOpaque = true
        contentView.addSubview(topSeparator)
        
        contentView.addSubview(articleCountLabel)
        contentView.addSubview(defaultListTag)
        
        let topRow = UIStackView(arrangedSubviews: [UIImageView(), UIImageView()])
        topRow.axis = NSLayoutConstraint.Axis.horizontal
        topRow.distribution = UIStackView.Distribution.fillEqually
        
        let bottomRow = UIStackView(arrangedSubviews: [UIImageView(), UIImageView()])
        bottomRow.axis = NSLayoutConstraint.Axis.horizontal
        bottomRow.distribution = UIStackView.Distribution.fillEqually
        
        gridImageViews = (topRow.arrangedSubviews + bottomRow.arrangedSubviews).compactMap { $0 as? UIImageView }

        gridImageViews.forEach {
            $0.accessibilityIgnoresInvertColors = true
            $0.contentMode = .scaleAspectFill
            $0.clipsToBounds = true
        }
        
        let outermostStackView = UIStackView(arrangedSubviews: [topRow, bottomRow])
        outermostStackView.axis = NSLayoutConstraint.Axis.vertical
        outermostStackView.distribution = UIStackView.Distribution.fillEqually
        
        imageGrid.addSubview(outermostStackView)
        outermostStackView.frame = imageGrid.frame
        outermostStackView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        imageGrid.layer.cornerRadius = 3
        imageGrid.layer.masksToBounds = true
        contentView.addSubview(imageGrid)
        
        super.setup()
    }
    
    open override func reset() {
        super.reset()
        bottomSeparator.isHidden = true
        topSeparator.isHidden = true
        titleTextStyle = .semiboldBody
        updateFonts(with: traitCollection)
    }
    
    override public func updateFonts(with traitCollection: UITraitCollection) {
        super.updateFonts(with: traitCollection)
        articleCountLabel.font = UIFont.wmf_font(.caption2, compatibleWithTraitCollection: traitCollection)
        defaultListTag.font = UIFont.wmf_font(.italicCaption2, compatibleWithTraitCollection: traitCollection)
    }
    
    override public func updateBackgroundColorOfLabels() {
        super.updateBackgroundColorOfLabels()
        articleCountLabel.backgroundColor = labelBackgroundColor
        defaultListTag.backgroundColor = labelBackgroundColor
    }
    
    override open func sizeThatFits(_ sz: CGSize, apply: Bool) -> CGSize {
        let size: CGSize = super.sizeThatFits(sz, apply: apply)
        let margins: UIEdgeInsets = calculatedLayoutMargins
        
        let minHeight = imageViewDimension + margins.top + margins.bottom
        let minHeightMinusMargins = minHeight - margins.top - margins.bottom
        
        let widthMinusMargins: CGFloat
        let labelsAdditionalSpacing: CGFloat = 20
        if !isImageGridHidden || !isImageViewHidden {
            widthMinusMargins = size.width - margins.left - margins.right - spacing - imageViewDimension - labelsAdditionalSpacing
        } else {
            widthMinusMargins = size.width - margins.left - margins.right
        }
        
        let x: CGFloat
        if isDeviceRTL {
            x = size.width - margins.left - widthMinusMargins
        } else {
            x = margins.left
        }
        
        var origin = CGPoint(x: x, y: margins.top)
        
        if displayType == .readingListsTab {
            let articleCountLabelSize = articleCountLabel.intrinsicContentSize
            let articleCountLabelX: CGFloat
            if isDeviceRTL {
                articleCountLabelX = size.width - articleCountLabelSize.width - margins.left
            } else {
                articleCountLabelX = origin.x
            }
            let articleCountLabelFrame = articleCountLabel.wmf_preferredFrame(at: CGPoint(x: articleCountLabelX, y: origin.y), maximumSize: articleCountLabelSize, alignedBy: articleSemanticContentAttribute, apply: apply)
            origin.y += articleCountLabelFrame.layoutHeight(with: spacing)
            articleCountLabel.isHidden = false
        } else {
            articleCountLabel.isHidden = true
        }
        
        let labelHorizontalAlignment: HorizontalAlignment
        if isDeviceRTL {
            labelHorizontalAlignment = .right
        } else {
            labelHorizontalAlignment = .left
        }
        
        if displayType == .addArticlesToReadingList {
            if isDefault {
                let titleLabelFrame = titleLabel.wmf_preferredFrame(at: origin, maximumWidth: widthMinusMargins, alignedBy: articleSemanticContentAttribute, apply: apply)
                origin.y += titleLabelFrame.layoutHeight(with: 0)
                let descriptionLabelFrame = descriptionLabel.wmf_preferredFrame(at: origin, maximumWidth: widthMinusMargins, alignedBy: articleSemanticContentAttribute, apply: apply)
                origin.y += descriptionLabelFrame.layoutHeight(with: 0)
            } else {
                let titleLabelFrame = titleLabel.wmf_preferredFrame(at: CGPoint(x: origin.x, y: margins.top), maximumSize: CGSize(width: widthMinusMargins, height: UIView.noIntrinsicMetric), minimumSize: CGSize(width: UIView.noIntrinsicMetric, height: minHeightMinusMargins), horizontalAlignment: labelHorizontalAlignment, verticalAlignment: .center, apply: apply)
                origin.y += titleLabelFrame.layoutHeight(with: 0)
            }
        } else if (descriptionLabel.wmf_hasText || !isImageGridHidden || !isImageViewHidden) {
            let titleLabelFrame = titleLabel.wmf_preferredFrame(at: origin, maximumWidth: widthMinusMargins, alignedBy: articleSemanticContentAttribute, apply: apply)
            origin.y += titleLabelFrame.layoutHeight(with: spacing)
            
            let descriptionLabelFrame = descriptionLabel.wmf_preferredFrame(at: origin, maximumWidth: widthMinusMargins, alignedBy: articleSemanticContentAttribute, apply: apply)
            origin.y += descriptionLabelFrame.layoutHeight(with: 0)
        } else {
            let titleLabelFrame = titleLabel.wmf_preferredFrame(at: origin, maximumSize: CGSize(width: widthMinusMargins, height: UIView.noIntrinsicMetric), minimumSize: CGSize(width: UIView.noIntrinsicMetric, height: minHeightMinusMargins), horizontalAlignment: labelHorizontalAlignment, verticalAlignment: .center, apply: apply)
            origin.y += titleLabelFrame.layoutHeight(with: 0)
            if !isAlertIconHidden || !isAlertLabelHidden {
                origin.y += titleLabelFrame.layoutHeight(with: spacing) + spacing * 2
            }
        }
        
        descriptionLabel.isHidden = !descriptionLabel.wmf_hasText

        origin.y += margins.bottom
        let height = max(origin.y, minHeight)
        let separatorXPositon: CGFloat = 0
        let separatorWidth = size.width

        if (apply) {
            if (!bottomSeparator.isHidden) {
                bottomSeparator.frame = CGRect(x: separatorXPositon, y: height - singlePixelDimension, width: separatorWidth, height: singlePixelDimension)
            }
            
            if (!topSeparator.isHidden) {
                topSeparator.frame = CGRect(x: separatorXPositon, y: 0, width: separatorWidth, height: singlePixelDimension)
            }
        }
        
        if (apply) {
            let imageViewY = floor(0.5*height - 0.5*imageViewDimension)
            let imageViewX: CGFloat
            if isDeviceRTL {
                imageViewX = margins.right
            } else {
                imageViewX = size.width - margins.right - imageViewDimension
            }
            imageGrid.frame = CGRect(x: imageViewX, y: imageViewY, width: imageViewDimension, height: imageViewDimension)
            imageGrid.isHidden = isImageGridHidden
            if (!isImageViewHidden) {
                imageView.frame = CGRect(x: imageViewX, y: imageViewY, width: imageViewDimension, height: imageViewDimension)
            }
        }
        
        let yAlignedWithImageBottom: CGFloat = imageGrid.frame.maxY - margins.bottom - (0.5 * spacing)
        
        if !isAlertIconHidden {
            let alertIconX: CGFloat
            if isDeviceRTL {
                alertIconX = size.width - alertIconDimension - margins.right
            } else {
                alertIconX = origin.x
            }
            alertIcon.frame = CGRect(x: alertIconX, y: yAlignedWithImageBottom, width: alertIconDimension, height: alertIconDimension)
            origin.y += alertIcon.frame.layoutHeight(with: 0)
        }
        
        if !isAlertLabelHidden {
            let alertLabelAvailableWidth: CGFloat
            if isAlertIconHidden {
                alertLabelAvailableWidth = widthMinusMargins
            } else {
                alertLabelAvailableWidth = widthMinusMargins - alertIconDimension - spacing
            }
            let alertLabelX: CGFloat
            let alertLabelY: CGFloat
            if isDeviceRTL && isAlertIconHidden {
                alertLabelX = alertIcon.frame.minX - alertLabelAvailableWidth - spacing
                alertLabelY = alertIcon.frame.midY - 0.5 * alertIconDimension
            } else if isAlertIconHidden {
                alertLabelX = origin.x
                alertLabelY = yAlignedWithImageBottom
            } else if isDeviceRTL {
                alertLabelX = alertIcon.frame.minX - alertLabelAvailableWidth - spacing
                alertLabelY = alertIcon.frame.midY - 0.5 * alertIconDimension
            } else {
                alertLabelX = alertIcon.frame.maxX + spacing
                alertLabelY = alertIcon.frame.midY - 0.5 * alertIconDimension
            }
            let alertLabelFrame = alertLabel.wmf_preferredFrame(at: CGPoint(x: alertLabelX, y: alertLabelY), maximumWidth: alertLabelAvailableWidth, alignedBy: articleSemanticContentAttribute, apply: apply)
            origin.y += alertLabelFrame.layoutHeight(with: 0)
        }
        
        if displayType == .readingListsTab && isDefault {
            let defaultListTagSize = defaultListTag.intrinsicContentSize
            let defaultListTagX: CGFloat
            if isDeviceRTL {
                defaultListTagX = size.width - defaultListTagSize.width - margins.right
            } else {
                defaultListTagX = origin.x
            }
            let defaultListTagY: CGFloat
            if !isAlertIconHidden || !isAlertLabelHidden {
                let alertMinY = isAlertIconHidden ? alertLabel.frame.minY : alertIcon.frame.minY
                defaultListTagY = descriptionLabel.frame.maxY + ((alertMinY - descriptionLabel.frame.maxY) * 0.25)
            } else {
                defaultListTagY = yAlignedWithImageBottom
            }
            defaultListTag.wmf_preferredFrame(at: CGPoint(x: defaultListTagX, y: defaultListTagY), maximumSize: defaultListTagSize, alignedBy: articleSemanticContentAttribute, apply: apply)
            defaultListTag.isHidden = false
        } else {
            defaultListTag.isHidden = true
        }

        return CGSize(width: size.width, height: height)
    }
    
    override public func configureForCompactList(at index: Int) {
        layoutMarginsAdditions.top = 5
        layoutMarginsAdditions.bottom = 5
        titleTextStyle = .subheadline
        descriptionTextStyle = .footnote
        updateFonts(with: traitCollection)
        imageViewDimension = 40
    }
    
    private var isImageGridHidden: Bool = false {
        didSet {
            imageGrid.isHidden = isImageGridHidden
            setNeedsLayout()
        }
    }
    
    public func configureAlert(for readingList: ReadingList, listLimit: Int, entryLimit: Int) {
        guard let error = readingList.APIError else {
            return
        }
        
        switch error {
        case .listLimit:
            isAlertLabelHidden = false
            isAlertIconHidden = false
            alertType = .listLimitExceeded(limit: listLimit)
        case .entryLimit:
            isAlertLabelHidden = false
            isAlertIconHidden = false
            alertType = .entryLimitExceeded(limit: entryLimit)
        default:
            isAlertLabelHidden = true
            isAlertIconHidden = true
        }
        
        let isAddArticlesToReadingListDisplayType = displayType == .addArticlesToReadingList
        isAlertIconHidden = isAddArticlesToReadingListDisplayType
        isAlertLabelHidden = isAddArticlesToReadingListDisplayType
    }
    
    public func configure(readingList: ReadingList, isDefault: Bool = false, index: Int, shouldShowSeparators: Bool = false, theme: Theme, for displayType: ReadingListsDisplayType, articleCount: Int64, lastFourArticlesWithLeadImages: [WMFArticle], layoutOnly: Bool) {
        configure(with: readingList.name, description: readingList.readingListDescription, isDefault: isDefault, index: index, shouldShowSeparators: shouldShowSeparators, theme: theme, for: displayType, articleCount: articleCount, lastFourArticlesWithLeadImages: lastFourArticlesWithLeadImages, layoutOnly: layoutOnly)
    }
    
    public func configure(with name: String?, description: String?, isDefault: Bool = false, index: Int, shouldShowSeparators: Bool = false, theme: Theme, for displayType: ReadingListsDisplayType, articleCount: Int64, lastFourArticlesWithLeadImages: [WMFArticle], layoutOnly: Bool) {
        
        articleSemanticContentAttribute = .unspecified
        
        imageViewDimension = 100

        self.displayType = displayType
        self.isDefault = isDefault
        self.articleCount = articleCount
    
        articleCountLabel.text = String.localizedStringWithFormat(CommonStrings.articleCountFormat, articleCount).uppercased()
        defaultListTag.text = WMFLocalizedString("saved-default-reading-list-tag", value: "This list cannot be deleted", comment: "Tag on the default reading list cell explaining that the list cannot be deleted")
        titleLabel.text = name
        descriptionLabel.text = description
        
        let imageWidthToRequest = imageView.frame.size.width < 300 ? traitCollection.wmf_nearbyThumbnailWidth : traitCollection.wmf_leadImageWidth
        let imageURLs = lastFourArticlesWithLeadImages.compactMap { $0.imageURL(forWidth: imageWidthToRequest) }
        
        isImageGridHidden = imageURLs.count != 4 // we need 4 images for the grid
        isImageViewHidden = !(isImageGridHidden && imageURLs.count >= 1) // we need at least one image to display
        
        if !layoutOnly && !isImageGridHidden {
            let _ = zip(gridImageViews, imageURLs).compactMap { $0.wmf_setImage(with: $1, detectFaces: true, onGPU: true, failure: { (error) in }, success: { })}
        }
        
        if isImageGridHidden, let imageURL = imageURLs.first {
            if !layoutOnly {
                imageView.wmf_setImage(with: imageURL, detectFaces: true, onGPU: true, failure: { (error) in }, success: { })
            }
        } else {
            isImageViewHidden = true
        }
        
        if displayType == .addArticlesToReadingList {
            configureForCompactList(at: index)
        }
        
        if shouldShowSeparators {
            topSeparator.isHidden = index > 0
            bottomSeparator.isHidden = false
        } else {
            bottomSeparator.isHidden = true
        }
        
        apply(theme: theme)
        extractLabel?.text = nil
        setNeedsLayout()
    }
    
    public override func apply(theme: Theme) {
        super.apply(theme: theme)
        bottomSeparator.backgroundColor = theme.colors.border
        topSeparator.backgroundColor = theme.colors.border
        articleCountLabel.textColor = theme.colors.secondaryText
        defaultListTag.textColor = theme.colors.secondaryText
    }
}


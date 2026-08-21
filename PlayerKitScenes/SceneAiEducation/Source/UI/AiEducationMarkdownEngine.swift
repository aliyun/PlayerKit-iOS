//
//  AiEducationMarkdownEngine.swift
//  AliPlayerKit
//
//  Created by keria on 2026/7/29.
//  Copyright © 2026 Alibaba Cloud. All rights reserved.
//

import UIKit
import GMarkdown

/// AI 教育场景 Markdown 渲染引擎。
///
/// 基于 GMarkdown（swift-markdown + MPITextKit）将 Markdown 分块解析为
/// `[GMarkChunk]`，并交由自带 UICollectionView 的 `GMarkdownMultiView` 渲染。
/// 与旧的 Down 方案不同，GMarkdown 输出的是「可嵌入的 UIView 组件」而非
/// `NSAttributedString`，因此对外提供两类能力：
///   1. `AiEducationMarkdownView`：可直接嵌入到卡片 / cell 中的渲染视图，
///      内部滚动被关闭，按内容高度撑开；
///   2. 本引擎：负责样式构建、分块解析与内容高度计算（同步返回）。
///
/// 排版样式对齐场景现有设计语言：正文 13pt / darkGray，
/// 标题 H1/H2/H3 加粗 18/16/15pt / black，代码块 Menlo + 浅灰底。
///
/// 内联彩色标签（`<font color>` / `<span style="color:">`）：GMarkdown 渲染产物为
/// 视图而非富文本，旧方案「渲染后对 token 区间着色」的后处理无法迁移，
/// 因此这里仅剥除颜色标签按无色渲染，颜色信息丢失（已知差异，见 stripColorTags）。
@objc(AiEducationMarkdownEngine)
public final class AiEducationMarkdownEngine: NSObject {

    // MARK: - Properties

    /// 引擎单例。
    @objc public static let shared = AiEducationMarkdownEngine()

    // MARK: - Lifecycle

    private override init() {
        super.init()
    }

    // MARK: - Public Methods

    /// 将 Markdown 文本按指定内容宽度解析为分块，并返回内容总高度。
    ///
    /// GMarkdown 的解析与尺寸计算是同步的：解析完成后每个 chunk 的 `itemSize`
    /// 已经算好，因此可同步得到内容总高度（用于 cell / header 布局）。
    ///
    /// - Parameters:
    ///   - markdown: Markdown 原文。
    ///   - width: 渲染内容宽度（即每个 chunk 的容器宽度）。
    /// - Returns: 解析出的分块数组，以及按该宽度渲染后的内容总高度。
    func makeChunks(_ markdown: String, width: CGFloat) -> (chunks: [GMarkChunk], height: CGFloat) {
        // 剥除颜色标签（内联颜色为已知差异，见类注释）
        let text = Self.stripColorTags(markdown)

        let parser = GMarkParser()
        let generator = GMarkChunkGenerator()
        generator.style = Self.makeStyle(width: width)

        let processor = GMarkProcessor(parser: parser, chunkGenerator: generator)
        let chunks = processor.process(markdown: text)

        // 布局无行间距 / 无 section inset，内容总高度即各 chunk 高度之和
        let height = chunks.reduce(0) { $0 + $1.itemSize.height }
        return (chunks, ceil(height))
    }

    // MARK: - Private Methods

    /// 构建排版样式：字体、颜色、代码块与容器宽度，对齐场景设计语言。
    ///
    /// `Default*Style` 结构体在 GMarkdown 内部不可见，因此以
    /// `MarkdownStyle.defaultStyle()` 为基底逐项覆盖。
    private static func makeStyle(width: CGFloat) -> Style {
        var style = MarkdownStyle.defaultStyle()

        // 容器宽度：驱动分块的宽度与高度计算
        style.maxContainerWidth = width

        // 字体：正文 13pt，标题 18/16/15pt（H4-H6 收敛为 14/13pt），行内代码 13pt
        style.fonts.current = .systemFont(ofSize: 13)
        style.fonts.paragraph = .systemFont(ofSize: 13)
        style.fonts.h1 = .boldSystemFont(ofSize: 18)
        style.fonts.h2 = .boldSystemFont(ofSize: 16)
        style.fonts.h3 = .boldSystemFont(ofSize: 15)
        style.fonts.h4 = .boldSystemFont(ofSize: 14)
        style.fonts.h5 = .boldSystemFont(ofSize: 13)
        style.fonts.h6 = .boldSystemFont(ofSize: 13)
        style.fonts.inlineCodeFont = UIFont(name: "Menlo", size: 12) ?? .systemFont(ofSize: 12)

        // 颜色：标题 black、正文 darkGray（对齐自研渲染器旧配色）
        style.colors.current = UIColor(white: 1.0, alpha: 0.8);
        style.colors.paragraph = UIColor(white: 1.0, alpha: 0.8);

        style.colors.h1 = .white
        style.colors.h2 = .white
        style.colors.h3 = .white
        style.colors.h4 = .white
        style.colors.h5 = .white
        style.colors.h6 = .white

        // 行内代码：暗红前景 + 浅灰背景
        style.colors.inlineCodeForeground = UIColor(red: 0.78, green: 0.14, blue: 0.18, alpha: 1.0)
        style.colors.inlineCodeBackground = UIColor(white: 0.94, alpha: 1.0)


        // 代码块：Menlo 12pt + 浅灰底
        style.codeBlockStyle.font = UIFont(name: "Menlo", size: 12) ?? .monospacedSystemFont(ofSize: 12, weight: .regular)
        style.codeBlockStyle.foregroundColor = .darkGray
        style.codeBlockStyle.backgroundColor = UIColor(white: 0.94, alpha: 1.0)

        // 列表：bullet 字体对齐正文
        style.listStyle.bulletFont = .systemFont(ofSize: 13)

        // 引用块：13pt 斜体 + darkGray（默认 18pt 太大）
        style.blockquoteStyle.font = .italicSystemFont(ofSize: 13)
        style.blockquoteStyle.textColor = UIColor(white: 1.0, alpha: 0.8)
        style.blockquoteStyle.backgroundColor = UIColor(white: 0.96, alpha: 1.0)
        style.blockquoteStyle.borderWidth = 3
        style.blockquoteStyle.padding = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)

        // 表格
        style.tableStyle.borderColor = UIColor(white: 0.85, alpha: 1.0)
        style.tableStyle.headerBackgroundColor = UIColor(white: 0.93, alpha: 1.0)
        style.tableStyle.rowAlternateBackgroundColor = UIColor(white: 0.97, alpha: 1.0)
        style.tableStyle.cellHeight = 36
        style.tableStyle.cellPadding = UIEdgeInsets(top: 4, left: 12, bottom: 4, right: 12)
        style.tableStyle.cellMaximumWidth = width - 32
        style.tableStyle.maximumNumberOfLines = 3

        // 图片
        style.imageStyle.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
        style.imageStyle.cornerRadius = 6

        // 全局
        style.hasStrikethrough = true
        style.maximumNumberOfLines = 0

        return style
    }

    // MARK: - Private Methods - Inline Color

    /// 颜色标签正则：四分支依次为 `<font color=...>`、`</font>`、
    /// `<span style="color:...">`、`</span>`，大小写不敏感、引号可单双可缺省。
    private static let colorTagRegex: NSRegularExpression? = {
        let pattern = "<font\\s+color\\s*=\\s*[\"']?([^\"'>\\s]+)[\"']?\\s*>"
            + "|</font\\s*>"
            + "|<span\\s+style\\s*=\\s*[\"']?\\s*color\\s*:\\s*([^\"';>]+?)\\s*;?\\s*[\"']?\\s*>"
            + "|</span\\s*>"
        return try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
    }()

    /// 剥除全部内联颜色标签，保证渲染文本中无原始 HTML 标签残留。
    ///
    /// GMarkdown 输出为视图，旧方案「渲染后对 token 区间着色」的后处理无法迁移，
    /// 故这里统一按无色渲染；颜色信息丢失属已知差异。
    static func stripColorTags(_ markdown: String) -> String {
        guard let regex = colorTagRegex else {
            return markdown
        }
        let range = NSRange(location: 0, length: (markdown as NSString).length)
        return regex.stringByReplacingMatches(in: markdown, options: [], range: range, withTemplate: "")
    }

}

/// AI 教育场景可嵌入的 Markdown 渲染视图。
///
/// 内部持有 `GMarkdownMultiView`（自带 UICollectionView 分块渲染），
/// 关闭其内部滚动并按内容高度撑开，供 Objective-C 侧以普通 `UIView` 嵌入
/// 卡片头部或 TableViewCell。渲染与高度计算同步完成。
@objc(AiEducationMarkdownView)
public final class AiEducationMarkdownView: UIView {

    // MARK: - Properties

    private let markdownView = GMarkdownMultiView()

    /// 最近一次渲染得到的内容高度。
    @objc public private(set) var contentHeight: CGFloat = 0

    // MARK: - Lifecycle

    override public init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        backgroundColor = .clear
        markdownView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(markdownView)
        NSLayoutConstraint.activate([
            markdownView.topAnchor.constraint(equalTo: topAnchor),
            markdownView.leadingAnchor.constraint(equalTo: leadingAnchor),
            markdownView.trailingAnchor.constraint(equalTo: trailingAnchor),
            markdownView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    // MARK: - Public Methods

    /// 按指定宽度渲染 Markdown，返回内容高度。
    ///
    /// 调用方应在获得返回高度后据此约束本视图的高度（cell 高度约束 /
    /// header frame），以保证内容完整展示且无内部滚动冲突。
    ///
    /// - Parameters:
    ///   - markdown: Markdown 原文。
    ///   - width: 渲染内容宽度。
    /// - Returns: 渲染后的内容高度。
    @objc @discardableResult
    public func render(markdown: String, width: CGFloat) -> CGFloat {
        let result = AiEducationMarkdownEngine.shared.makeChunks(markdown, width: width)
        markdownView.updateMarkdown(result.chunks)
        disableInnerScroll()
        contentHeight = result.height
        return result.height
    }

    // MARK: - Private Methods

    /// 关闭内部 UICollectionView 的滚动，避免与外层列表产生嵌套滚动冲突。
    private func disableInnerScroll() {
        for subview in markdownView.subviews {
            if let scrollView = subview as? UIScrollView {
                scrollView.isScrollEnabled = false
                scrollView.bounces = false
            }
        }
    }

}

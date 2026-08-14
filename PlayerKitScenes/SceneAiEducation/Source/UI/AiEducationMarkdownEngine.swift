//
//  AiEducationMarkdownEngine.swift
//  AliPlayerKit
//
//  Created by keria on 2026/7/29.
//  Copyright © 2026 Alibaba Cloud. All rights reserved.
//

import UIKit
import Down

/// AI 教育场景 Markdown 渲染引擎。
///
/// 基于 Down（cmark）将 Markdown 渲染为富文本，
/// 排版样式对齐场景现有设计语言：正文 13pt / darkGray，
/// 标题 H1/H2/H3 加粗 18/16/15pt / black，代码块 Menlo + 浅灰底。
/// 支持内联彩色标签（<font color> / <span style="color:">）：
/// 预处理阶段替换为私有区成对 token，Down 渲染后对 token 区间施加前景色；
/// 任一环节异常或标签不成对时剥除颜色标签按无色渲染。
/// 供 Objective-C 侧 AiEducationMarkdownRenderer 门面调用，
/// 渲染失败时返回 nil，由门面降级为原文富文本。
@objc(AiEducationMarkdownEngine)
public final class AiEducationMarkdownEngine: NSObject {

    // MARK: - Properties

    /// 引擎单例。
    @objc public static let shared = AiEducationMarkdownEngine()

    /// Down 样式器，按场景设计语言定制，可复用（无状态渲染）。
    private let styler: DownStyler

    // MARK: - Lifecycle

    private override init() {
        styler = DownStyler(configuration: Self.makeConfiguration())
        super.init()
    }

    // MARK: - Public Methods

    /// 将 Markdown 文本渲染为富文本（含内联彩色标签支持）。
    ///
    /// - Parameter markdown: Markdown 原文。
    /// - Returns: 渲染后的富文本；解析或渲染失败时返回 nil。
    @objc public func render(_ markdown: String) -> NSAttributedString? {
        // 预处理：颜色标签替换为私有区成对 token；不成对时已降级为剥除标签的无色文本
        let prepared = Self.prepareInlineColors(markdown)
        if let rendered = try? Down(markdownString: prepared.text).toAttributedString(styler: styler) {
            return Self.applyInlineColors(to: rendered, colors: prepared.colors)
        }
        // 降级：剥除颜色标签后按无色渲染，仍失败则交由门面降级为原文
        let stripped = Self.stripColorTags(markdown)
        return try? Down(markdownString: stripped).toAttributedString(styler: styler)
    }

    // MARK: - Private Methods

    /// 构建排版配置：字体、颜色、段落样式、列表与代码块选项。
    private static func makeConfiguration() -> DownStylerConfiguration {
        // 字体：正文 13pt，标题 18/16/15pt（H4-H6 收敛为 14/13pt），代码 Menlo 12pt
        let fonts = StaticFontCollection(
            heading1: .boldSystemFont(ofSize: 18),
            heading2: .boldSystemFont(ofSize: 16),
            heading3: .boldSystemFont(ofSize: 15),
            heading4: .boldSystemFont(ofSize: 14),
            heading5: .boldSystemFont(ofSize: 13),
            heading6: .boldSystemFont(ofSize: 13),
            body: .systemFont(ofSize: 13),
            code: UIFont(name: "Menlo", size: 12) ?? .systemFont(ofSize: 12),
            listItemPrefix: .monospacedDigitSystemFont(ofSize: 13, weight: .regular)
        )

        // 颜色：标题 black、正文 darkGray、代码块浅灰底（对齐自研渲染器旧配色）
        let colors = StaticColorCollection(
            heading1: .black,
            heading2: .black,
            heading3: .black,
            heading4: .black,
            heading5: .black,
            heading6: .black,
            body: .darkGray,
            code: .darkGray,
            listItemPrefix: .darkGray,
            codeBlockBackground: UIColor(white: 0.94, alpha: 1.0)
        )

        // 段落样式：标题段前距，正文约 1.3 倍行距（13pt 字号下行距 ~4pt）+ 段后距
        let headingStyle = NSMutableParagraphStyle()
        headingStyle.paragraphSpacingBefore = 10
        headingStyle.paragraphSpacing = 6

        let bodyStyle = NSMutableParagraphStyle()
        bodyStyle.lineSpacing = 4
        bodyStyle.paragraphSpacing = 7

        let codeStyle = NSMutableParagraphStyle()
        codeStyle.lineSpacing = 2
        codeStyle.paragraphSpacingBefore = 6
        codeStyle.paragraphSpacing = 6

        var paragraphStyles = StaticParagraphStyleCollection()
        paragraphStyles.heading1 = headingStyle
        paragraphStyles.heading2 = headingStyle
        paragraphStyles.heading3 = headingStyle
        paragraphStyles.heading4 = headingStyle
        paragraphStyles.heading5 = headingStyle
        paragraphStyles.heading6 = headingStyle
        paragraphStyles.body = bodyStyle
        paragraphStyles.code = codeStyle

        // 列表：前缀后间距收敛为 6pt，使项目符号与正文缩进对齐更紧凑
        let listItemOptions = ListItemOptions(maxPrefixDigits: 2,
                                              spacingAfterPrefix: 6,
                                              spacingAbove: 2,
                                              spacingBelow: 4)

        // 代码块：容器内边距 8pt，配合浅灰底色
        let codeBlockOptions = CodeBlockOptions(containerInset: 8)

        return DownStylerConfiguration(fonts: fonts,
                                       colors: colors,
                                       paragraphStyles: paragraphStyles,
                                       listItemOptions: listItemOptions,
                                       codeBlockOptions: codeBlockOptions)
    }

    // MARK: - Private Methods - Inline Color

    /// 预处理结果：token 化后的文本与 token 索引 → 颜色映射。
    private struct InlineColorPrepared {
        let text: String
        let colors: [Int: UIColor]
    }

    /// 私有区 token 起始码位，成对占用：open = base + 2i，close = base + 2i + 1。
    private static let tokenBase: UInt32 = 0xE000

    /// 颜色标签正则：四分支依次为 <font color=...>、</font>、<span style="color:...">、</span>，
    /// 大小写不敏感、引号可单双可缺省。
    private static let colorTagRegex: NSRegularExpression? = {
        let pattern = "<font\\s+color\\s*=\\s*[\"']?([^\"'>\\s]+)[\"']?\\s*>"
            + "|</font\\s*>"
            + "|<span\\s+style\\s*=\\s*[\"']?\\s*color\\s*:\\s*([^\"';>]+?)\\s*;?\\s*[\"']?\\s*>"
            + "|</span\\s*>"
        return try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
    }()

    /// 预处理：成对颜色标签替换为私有区 token 并记录颜色；
    /// 标签不成对（闭合不匹配 / 未闭合）时降级为剥除全部颜色标签的无色文本。
    private static func prepareInlineColors(_ markdown: String) -> InlineColorPrepared {
        guard let regex = colorTagRegex else {
            return InlineColorPrepared(text: markdown, colors: [:])
        }
        // 冲突检测：原文含 token 预留码位区间内的私有区字符时，
        // token 定位会误认/误删用户字符，直接降级为剥标签无色渲染
        let hasTokenConflict = markdown.unicodeScalars.contains {
            $0.value >= tokenBase && $0.value < tokenBase + 0x0100
        }
        if hasTokenConflict {
            return InlineColorPrepared(text: stripColorTags(markdown), colors: [:])
        }
        let source = markdown as NSString
        let matches = regex.matches(in: markdown, options: [], range: NSRange(location: 0, length: source.length))
        if matches.isEmpty {
            return InlineColorPrepared(text: markdown, colors: [:])
        }

        var result = ""
        var colors: [Int: UIColor] = [:]
        // 嵌套配对栈：元素为（是否 font 标签, token 索引；颜色不可解时索引为 nil 仅参与配对）
        var stack: [(isFont: Bool, index: Int?)] = []
        var counter = 0
        var cursor = 0
        var balanced = true

        for match in matches {
            result += source.substring(with: NSRange(location: cursor, length: match.range.location - cursor))
            cursor = match.range.location + match.range.length
            let matchedText = source.substring(with: match.range).lowercased()

            if matchedText.hasPrefix("</") {
                // 闭合标签：必须与栈顶同类型，否则视为不成对
                let isFontClose = matchedText.hasPrefix("</font")
                guard let top = stack.last, top.isFont == isFontClose else {
                    balanced = false
                    break
                }
                stack.removeLast()
                if let index = top.index, let scalar = UnicodeScalar(tokenBase + UInt32(index) * 2 + 1) {
                    result.append(Character(scalar))
                }
            } else {
                // 开启标签：解析颜色，可解时分配 token 索引，不可解时仅剥除标签
                let isFontOpen = matchedText.hasPrefix("<font")
                let groupRange = match.range(at: isFontOpen ? 1 : 2)
                let rawColor = groupRange.location != NSNotFound ? source.substring(with: groupRange) : ""
                if let color = parseColor(rawColor), let scalar = UnicodeScalar(tokenBase + UInt32(counter) * 2) {
                    colors[counter] = color
                    result.append(Character(scalar))
                    stack.append((isFont: isFontOpen, index: counter))
                    counter += 1
                } else {
                    stack.append((isFont: isFontOpen, index: nil))
                }
            }
        }

        if !balanced || !stack.isEmpty {
            // 降级：剥除全部颜色标签按无色渲染
            return InlineColorPrepared(text: stripColorTags(markdown), colors: [:])
        }
        result += source.substring(from: cursor)
        return InlineColorPrepared(text: result, colors: colors)
    }

    /// 剥除全部颜色标签（降级路径，保证无原始 HTML 标签残留）。
    private static func stripColorTags(_ markdown: String) -> String {
        guard let regex = colorTagRegex else {
            return markdown
        }
        let range = NSRange(location: 0, length: (markdown as NSString).length)
        return regex.stringByReplacingMatches(in: markdown, options: [], range: range, withTemplate: "")
    }

    /// 后处理：定位成对 token 对区间施加前景色，随后删除成对 token 字符；
    /// token 不成对时整体跳过该对的着色与删除，保证不误删任何字符。
    private static func applyInlineColors(to attributed: NSAttributedString,
                                          colors: [Int: UIColor]) -> NSAttributedString {
        guard !colors.isEmpty else {
            return attributed
        }
        let result = NSMutableAttributedString(attributedString: attributed)
        let text = result.string as NSString
        var tokenRanges: [NSRange] = []

        for (index, color) in colors.sorted(by: { $0.key < $1.key }) {
            guard let openScalar = UnicodeScalar(tokenBase + UInt32(index) * 2),
                  let closeScalar = UnicodeScalar(tokenBase + UInt32(index) * 2 + 1) else {
                continue
            }
            let openRange = text.range(of: String(openScalar))
            let closeRange = text.range(of: String(closeScalar))
            // 仅成对且顺序正确时才着色并删除；孤立 token 整体跳过，不加入删除列表
            guard openRange.location != NSNotFound,
                  closeRange.location != NSNotFound,
                  closeRange.location > openRange.location + openRange.length else {
                continue
            }
            let colorRange = NSRange(location: openRange.location + openRange.length,
                                     length: closeRange.location - openRange.location - openRange.length)
            result.addAttribute(.foregroundColor, value: color, range: colorRange)
            tokenRanges.append(openRange)
            tokenRanges.append(closeRange)
        }

        // 从后往前删除 token 字符，避免位置偏移
        for range in tokenRanges.sorted(by: { $0.location > $1.location }) {
            result.deleteCharacters(in: range)
        }
        return result
    }

    /// 解析颜色值：支持 #RRGGBB、#RGB 与常见颜色名；不可解返回 nil。
    private static func parseColor(_ raw: String) -> UIColor? {
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if value.isEmpty {
            return nil
        }
        if value.hasPrefix("#") {
            var hex = String(value.dropFirst())
            if hex.count == 3 {
                hex = hex.map { "\($0)\($0)" }.joined()
            }
            guard hex.count == 6, let intValue = UInt32(hex, radix: 16) else {
                return nil
            }
            return UIColor(red: CGFloat((intValue >> 16) & 0xFF) / 255.0,
                           green: CGFloat((intValue >> 8) & 0xFF) / 255.0,
                           blue: CGFloat(intValue & 0xFF) / 255.0,
                           alpha: 1.0)
        }
        let namedColors: [String: UIColor] = [
            "red": .red,
            "blue": .blue,
            "green": .green,
            "orange": .orange,
            "yellow": .yellow,
            "purple": .purple,
            "gray": .gray,
            "grey": .gray,
            "black": .black,
            "white": .white,
            "brown": .brown,
            "cyan": .cyan,
            "magenta": .magenta,
        ]
        return namedColors[value]
    }

}

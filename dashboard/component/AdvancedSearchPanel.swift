import SwiftUI

struct AdvancedSearchPanel: View {
    private enum FieldKind { case text, number, array }
    private struct Field: Identifiable {
        let key: String
        let title: String
        let kind: FieldKind
        var id: String { key }
    }

    let isActive: Bool
    let allowsDownloadMetrics: Bool
    let onApply: (SearchExpression) -> Void
    let onClear: () -> Void

    @State private var useAnd = true
    @State private var conditions = [SearchCondition()]
    @State private var validationMessage: String?

    private var fields: [Field] {
        var values: [Field] = [
            .init(key: "name", title: "应用名称", kind: .text),
            .init(key: "pkg_name", title: "包名", kind: .text),
            .init(key: "developer_name", title: "开发者", kind: .text),
            .init(key: "kind_name", title: "分类", kind: .text),
            .init(key: "kind_type_name", title: "分类类型", kind: .text),
            .init(key: "average_rating", title: "平均评分", kind: .number),
            .init(key: "total_star_rating_count", title: "评分数量", kind: .number),
            .init(key: "minsdk", title: "最低 SDK", kind: .number),
            .init(key: "target_sdk", title: "目标 SDK", kind: .number),
            .init(key: "main_device_codes", title: "支持设备", kind: .array),
        ]
        if allowsDownloadMetrics {
            values.insert(.init(key: "download_count", title: "下载量", kind: .number), at: 5)
        }
        return values
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text("高级组合搜索").font(.headline)
                    Text("支持逻辑组合、比较、空值判断与数组条件")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                if isActive {
                    Text("已生效").font(.caption.bold()).foregroundStyle(.white)
                        .padding(.horizontal, 9).padding(.vertical, 5)
                        .background(.tint, in: Capsule())
                }
            }

            Picker("条件关系", selection: $useAnd) {
                Text("所有条件（AND）").tag(true)
                Text("任一条件（OR）").tag(false)
            }
            .pickerStyle(.segmented)

            ForEach($conditions) { $condition in
                conditionRow($condition)
            }

            if let validationMessage {
                Text(validationMessage).font(.caption).foregroundStyle(.red)
            }

            ViewThatFits(in: .horizontal) {
                HStack { actionButtons }
                VStack { actionButtons }
            }
        }
        .padding(14)
        .background(.quaternary.opacity(0.25), in: RoundedRectangle(cornerRadius: 16))
    }

    private func conditionRow(_ condition: Binding<SearchCondition>) -> some View {
        let field = fields.first(where: { $0.key == condition.wrappedValue.key }) ?? fields[0]
        return VStack(alignment: .leading, spacing: 8) {
            ViewThatFits(in: .horizontal) {
                HStack { conditionControls(condition, field: field) }
                VStack { conditionControls(condition, field: field) }
            }
            if field.kind == .array, condition.wrappedValue.op.needsValue {
                Text("数组值可用英文逗号分隔，例如 phone,tablet")
                    .font(.caption2).foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private func conditionControls(_ condition: Binding<SearchCondition>, field: Field) -> some View {
        Picker("字段", selection: condition.key) {
            ForEach(fields) { Text($0.title).tag($0.key) }
        }
        .onChange(of: condition.wrappedValue.key) {
            condition.wrappedValue.op = defaultOperator(for: fields.first(where: { $0.key == condition.wrappedValue.key })?.kind ?? .text)
        }
        Picker("操作符", selection: condition.op) {
            ForEach(operators(for: field.kind)) { Text($0.title).tag($0) }
        }
        if condition.wrappedValue.op.needsValue {
            TextField("输入条件值", text: Binding(
                get: { condition.wrappedValue.value ?? "" },
                set: { condition.wrappedValue.value = $0 }
            ))
            .textFieldStyle(.roundedBorder)
            .frame(minWidth: 160)
        }
        if conditions.count > 1 {
            Button("删除", systemImage: "minus.circle", role: .destructive) {
                conditions.removeAll { $0.id == condition.wrappedValue.id }
            }
            .labelStyle(.iconOnly)
        }
    }

    @ViewBuilder
    private var actionButtons: some View {
        Button("添加条件", systemImage: "plus") { conditions.append(SearchCondition()) }
            .buttonStyle(.bordered)
        Button("应用高级搜索", systemImage: "checkmark") {
            guard let expression = SearchExpression.build(useAnd: useAnd, conditions: conditions) else {
                validationMessage = "请至少完整填写一个查询条件"
                return
            }
            validationMessage = nil
            onApply(expression)
        }
        .buttonStyle(.borderedProminent)
        Button("清除高级搜索", systemImage: "xmark") {
            conditions = [SearchCondition()]
            useAnd = true
            validationMessage = nil
            onClear()
        }
        .buttonStyle(.bordered)
    }

    private func operators(for kind: FieldKind) -> [SearchOperator] {
        switch kind {
        case .text:
            [.equal, .notEqual, .like, .notLike, .caseInsensitiveLike, .notCaseInsensitiveLike, .isNull, .isNotNull]
        case .number:
            [.equal, .notEqual, .greaterThan, .greaterThanOrEqual, .lessThan, .lessThanOrEqual, .isNull, .isNotNull]
        case .array:
            [.arrayContains, .arrayOverlaps, .arrayContainedBy, .isNull, .isNotNull]
        }
    }

    private func defaultOperator(for kind: FieldKind) -> SearchOperator {
        switch kind {
        case .text: .caseInsensitiveLike
        case .number: .greaterThanOrEqual
        case .array: .arrayContains
        }
    }
}

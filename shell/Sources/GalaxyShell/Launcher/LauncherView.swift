import SwiftUI

struct LauncherView: View {
    static let width: CGFloat = 640
    static let height: CGFloat = 420

    @ObservedObject var model: LauncherModel
    let onChoose: (LauncherItem) -> Void
    let onCancel: () -> Void

    @FocusState private var searchFocused: Bool

    init(model: LauncherModel,
         onChoose: @escaping (LauncherItem) -> Void,
         onCancel: @escaping () -> Void) {
        self.model = model
        self.onChoose = onChoose
        self.onCancel = onCancel
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 20))
                    .foregroundStyle(Theme.panelSecondaryText)
                TextField("Search apps, files and actions", text: $model.query)
                    .textFieldStyle(.plain)
                    .font(.system(size: 22))
                    .foregroundStyle(Theme.panelText)
                    .focused($searchFocused)
                    .onSubmit { if let item = model.selectedItem { onChoose(item) } }
                    .onKeyPress(.downArrow) { model.move(1); return .handled }
                    .onKeyPress(.upArrow) { model.move(-1); return .handled }
                    .onKeyPress(.escape) { onCancel(); return .handled }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)

            Divider()

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(Array(model.results.enumerated()), id: \.element.id) { index, item in
                            row(item, selected: index == model.selection)
                                .id(index)
                                .contentShape(Rectangle())
                                .onTapGesture { onChoose(item) }
                        }
                    }
                    .padding(8)
                }
                .onChange(of: model.selection) { _, newValue in
                    proxy.scrollTo(newValue)
                }
            }
        }
        .frame(width: Self.width, height: Self.height)
        .background(Theme.panelBackground)
        .onAppear { searchFocused = true }
        .onChange(of: model.openCount) { _, _ in searchFocused = true }
    }

    private func row(_ item: LauncherItem, selected: Bool) -> some View {
        HStack(spacing: 12) {
            if let icon = item.icon {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 28, height: 28)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(item.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.panelText)
                    .lineLimit(1)
                Text(item.subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.panelSecondaryText)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(selected ? Theme.selection : Color.clear)
        )
    }
}

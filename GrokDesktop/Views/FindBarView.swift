import SwiftUI

struct FindBarView: View {
    @ObservedObject var session: GrokSession
    @FocusState private var focused: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Find", text: $session.findQuery)
                .textFieldStyle(.plain)
                .focused($focused)
                .onSubmit { session.find(session.findQuery) }
                .onChange(of: session.findQuery) { _, newValue in
                    session.find(newValue)
                }
            if !session.findMatchFound && !session.findQuery.isEmpty {
                Text("Not found")
                    .foregroundStyle(.red)
                    .font(.caption)
            }
            Button("Previous") { session.find(session.findQuery, backwards: true) }
                .controlSize(.small)
            Button("Next") { session.find(session.findQuery) }
                .controlSize(.small)
            Button {
                session.hideFind()
            } label: {
                Image(systemName: "xmark")
            }
            .buttonStyle(.plain)
            .help("Close")
        }
        .font(.system(size: 12))
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.bar)
        .overlay(alignment: .bottom) { Divider() }
        .onAppear { focused = true }
        .onExitCommand { session.hideFind() }
    }
}

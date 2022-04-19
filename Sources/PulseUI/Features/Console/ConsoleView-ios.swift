// The MIT License (MIT)
//
// Copyright (c) 2020–2022 Alexander Grebenyuk (github.com/kean).

import SwiftUI
import CoreData
import PulseCore
import Combine

#if os(iOS)

@available(iOS 13.0, *)
public struct ConsoleView: View {
    @ObservedObject var viewModel: ConsoleViewModel
    @Environment(\.colorScheme) private var colorScheme: ColorScheme
    @State private var shared: ShareItems?

    public init(store: LoggerStore = .default,
                configuration: ConsoleConfiguration = .default) {
        self.viewModel = ConsoleViewModel(store: store)
    }

    init(viewModel: ConsoleViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        contentView
            .navigationBarTitle(Text("Console"))
            .navigationBarItems(
                leading: viewModel.onDismiss.map {
                    Button(action: $0) { Image(systemName: "xmark") }
                },
                trailing: actionButton
            )
            .sheet(item: $shared) { ShareView($0).id($0.id) }
    }

    private var contentView: some View {
        List {
            QuickFiltersView(model: viewModel)
            if !viewModel.messages.isEmpty {
                ConsoleMessagesForEach(context: viewModel.context, messages: viewModel.messages, searchCriteriaViewModel: viewModel.searchCriteria)
            }
        }.listStyle(PlainListStyle())
            .background(overlay)
    }

    @ViewBuilder
    private var overlay: some View {
        if viewModel.messages.isEmpty {
            placeholder
        }
    }

    private var placeholder: PlaceholderView {
        let message: String
        if viewModel.searchCriteria.isDefaultSearchCriteria {
            if viewModel.searchCriteria.criteria.dates.isCurrentSessionOnly {
                message = "There are no messages in a current session."
            } else {
                message = "There are currently no stored messages."
            }
        } else {
            message = "There are no messages for the selected filters"
        }
        return PlaceholderView(imageName: "message", title: "No Messages", subtitle: message)
    }

    @ViewBuilder
    private var actionButton: some View {
        if #available(iOS 14.0, *) {
            Menu(content: {
                if viewModel.configuration.isStoreSharingEnabled {
                    Section {
                        Button(action: { shared = viewModel.share(as: .store) }) {
                            Label("Share as Pulse Document", systemImage: "square.and.arrow.up")
                        }
                        Button(action: { shared = viewModel.share(as: .text) }) {
                            Label("Share as Text File", systemImage: "square.and.arrow.up")
                        }
                    }
                }
                Section {
                    ButtonRemoveAll(action: viewModel.buttonRemoveAllMessagesTapped)
                        .disabled(viewModel.messages.isEmpty)
                        .opacity(viewModel.messages.isEmpty ? 0.33 : 1)
                }
            }, label: {
                Image(systemName: "ellipsis.circle")
            })
        } else {
            if viewModel.configuration.isStoreSharingEnabled {
                ShareButton { shared = viewModel.share(as: .store) }
            }
        }
    }
}

@available(iOS 13, *)
private struct QuickFiltersView: View {
    @ObservedObject var model: ConsoleViewModel
    @State private var isShowingFilters = false

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 16) {
                SearchBar(title: "Search \(model.messages.count) messages", text: $model.filterTerm)
                Button(action: {
                    isShowingFilters = true
                }) {
                    Image(systemName: "line.horizontal.3.decrease.circle")
                        .foregroundColor(.accentColor)
                }.buttonStyle(.plain)
            }
            ConsoleQuickFiltersView(filters: model.quickFilters)
        }
        .padding(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
        .sheet(isPresented: $isShowingFilters) {
            NavigationView {
                ConsoleFiltersView(viewModel: model.searchCriteria, isPresented: $isShowingFilters)
            }
        }
    }
}

#if DEBUG
@available(iOS 13.0, *)
struct ConsoleView_Previews: PreviewProvider {
    static var previews: some View {
        return Group {
            ConsoleView(viewModel: .init(store: .mock))
            ConsoleView(viewModel: .init(store: .mock))
                .environment(\.colorScheme, .dark)
        }
    }
}
#endif
#endif

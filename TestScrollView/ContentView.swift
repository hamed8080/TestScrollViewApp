//
//  ContentView.swift
//  TestScrollView
//
//  Created by hamed on 7/5/23.
//

import SwiftUI

struct ViewOffsetKey: PreferenceKey {
    typealias Value = CGFloat
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value += nextValue()
    }
}

struct MessageSection: Identifiable {
    var id = UUID()
    var date: Date
    var messages: [Message]
}

struct Message: Identifiable, Hashable, Equatable {
    let id: Int
    let text: String
    let date: Date
    static func == (lhs: Message, rhs: Message) -> Bool {
        rhs.id == lhs.id
    }
}

class ViewModel: ObservableObject {
    var sections: [MessageSection] = [.init(date: .now, messages: (0...7000).map({Message(id: $0, text: "Text\($0)", date: .now)}))]
    var lastVisibleId = 0
    var scrollView: ScrollViewProxy?
    var scrollingUP = false
    var lastOrigin: CGFloat = 0
    var isLoading: Bool = false
    var disableScrolling = false

    func setNewOrigin(newOriginY: CGFloat) {
        lastOrigin = newOriginY
    }

    func loadMoreAtTop() {
        withAnimation {
            isLoading = true
            self.objectWillChange.send()
        }
        scrollingUP = false
        let oldTopItem = sections.first?.messages.first
        let oldTopItemId = oldTopItem?.id ?? 0
        Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
            self.disableScrolling = true
            self.objectWillChange.send()
            let firstId = abs(oldTopItemId) + 1
            let endId = firstId + 20000
            let previousDate = Calendar.current.date(byAdding: .day, value: -1, to: oldTopItem?.date ?? .now)!
            let messages: [Message] = (firstId...endId).map({.init(id: -$0, text: "Text-\(-$0)", date: previousDate)})
            self.sections.insert(.init(date: previousDate, messages: messages.sorted(by: {$0.id < $1.id})), at: 0)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation {
                    self.disableScrolling = false
                    self.scrollView?.scrollTo(oldTopItemId, anchor: .top)
                    self.isLoading = false
                    self.objectWillChange.send()
                }
            }
        }
    }

    func addToBottom() {
        let lastMessage = sections.last?.messages.last
        let id = (lastMessage?.id ?? 0) + 1
        let newDate = Calendar.current.date(byAdding: .day, value: 1, to: lastMessage?.date ?? .now)!
        sections.append(.init(date: newDate, messages: [.init(id: id, text: "Added Text-\(id)", date: newDate)]))
        objectWillChange.send()
    }

    func scrollToBottom() {
        let lastMessage = sections.last?.messages.last
        lastVisibleId = lastMessage?.id ?? 0
        scrollTo(lastVisibleId)
    }

    func scrollTo(_ id: Int, animation: Animation? = .easeInOut, anchor: UnitPoint? = .bottom) {
        objectWillChange.send()
        Timer.scheduledTimer(withTimeInterval: 0.002, repeats: false) { [weak self] timer in
            withAnimation(animation) {
                self?.scrollView?.scrollTo(id, anchor: anchor)
            }
        }
    }

    func addNewMessageAndMoveToBottom() {
        let lastMessage = sections.last?.messages.last
        let newDate = Calendar.current.date(byAdding: .day, value: 1, to: lastMessage?.date ?? .now)!
        let id = (lastMessage?.id ?? 0) + 1
        sections.append(.init(date: newDate, messages: [.init(id: id, text: "Added Text-\(id)", date: newDate)]))
        scrollTo(id)
    }

    func addToTop() {
        let first = sections.first?.messages.first
        let previousDate = Calendar.current.date(byAdding: .day, value: -1, to: first?.date ?? .now)!
        let id = (first?.id ?? 0) - 1
        sections.append(.init(date: previousDate, messages: [.init(id: id, text: "Added Text-\(id)", date: previousDate)]))
        self.sections.sort(by: {$0.date < $1.date})
        objectWillChange.send()
    }
    
}

struct TextMessageRow: View {
    var message: Message
    let viewModel: ViewModel

    var body: some View {
        Text(message.text)
            .id(message.id)
            .padding(24)
            .background(.red.opacity(0.5))
            .onAppear {
                viewModel.lastVisibleId = message.id
                print("On Appear: \(message.text)")
            }
    }
}

struct ContentView: View {
    var body: some View {
        NavigationSplitView {
            Text("SideBar")
        } content: {
            Text("Second")
        } detail: {
            DetailView()
        }
    }
}

struct DetailView: View {
    var body: some View {
        ScrollViewReader { scrollView in
            ScrollViewContent(scrollView: scrollView)
        }
    }
}

struct ScrollViewContent: View {
    var scrollView: ScrollViewProxy
    @StateObject var viewModel = ViewModel()

    var body: some View {
        ScrollView {
            if viewModel.isLoading {
                Text(verbatim: "IsLoading")
            }
            LazyVStack(spacing: 8) {
                ForEach(viewModel.sections) { section in
                    Section(section.date.description) {
                        ForEach(section.messages) { message in
                            TextMessageRow(message: message, viewModel: viewModel)
                        }
                    }
                }
            }
            .background(geometryBackground)
            .padding(.bottom)
            .padding([.leading, .trailing])
        }
        .disabled(viewModel.disableScrolling)
        .environmentObject(viewModel)
        .background(.mint)
        .coordinateSpace(name: "scroll")
        .gesture(dragGesture)
        .onPreferenceChange(ViewOffsetKey.self) { originY in
            print("originY changed: \(originY)")
            viewModel.setNewOrigin(newOriginY: originY)
            if originY < 320, viewModel.scrollingUP, !viewModel.isLoading {
                viewModel.loadMoreAtTop()
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                NavigationLink {
                    Text("dd")
                } label: {
                    Image("profile")
                        .resizable()
                        .frame(width: 32, height: 32)
                        .scaledToFit()
                        .cornerRadius(16)
                }
                toolbars
            }
        }
        .onAppear {
            viewModel.scrollView = scrollView
            viewModel.scrollToBottom()
        }

    }

    var dragGesture: some Gesture {
        DragGesture()
            .onChanged { newValue in
                if newValue.translation.height > 0 {
                    viewModel.scrollingUP = true
                } else {
                    viewModel.scrollingUP = false
                }
            }
    }

    private var geometryBackground: some View {
        GeometryReader {
            Color.clear.preference(key: ViewOffsetKey.self, value: -$0.frame(in: .named("scroll")).origin.y)
        }
    }

    private var toolbars: some View {
        Menu("Menu") {
            Button {
                viewModel.addToTop()
            } label: {
                Text(verbatim: "Add To Top")
            }

            Button {
                viewModel.addToBottom()
            } label: {
                Text(verbatim: "Add To Bottom")
            }

            Button {
                viewModel.addNewMessageAndMoveToBottom()
            } label: {
                Text(verbatim: "Add new Item At the end fo the List and go to bottom")
            }

            Button {
                viewModel.scrollToBottom()
            } label: {
                Text(verbatim: "go To Bottom of Lsit")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

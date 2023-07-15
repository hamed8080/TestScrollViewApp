//
//  ContentView.swift
//  TestScrollView
//
//  Created by hamed on 7/5/23.
//

import SwiftUI


class ViewModelArray: ObservableObject {
    var messages: [Message] = (0...7000).map({Message(id: $0, text: "Text\($0)", date: .now)})
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
            objectWillChange.send()
        }
        scrollingUP = false
        let oldTopItemId = messages.first?.id ?? 0
        Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
            self.disableScrolling = true
            self.objectWillChange.send()
            let firstId = abs(oldTopItemId) + 1
            let endId = firstId + 20000
            let messages: [Message] = (firstId...endId).map({.init(id: -$0, text: "Added Text-\(-$0)", date: .now)}).sorted(by: {$0.id < $1.id})
            self.messages.append(contentsOf: messages)
            self.messages.sort(by: {$0.id < $1.id})
            self.objectWillChange.send()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
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
        let lastMessage = messages.last
        let id = (lastMessage?.id ?? 0) + 1
        let newDate = Calendar.current.date(byAdding: .day, value: 1, to: lastMessage?.date ?? .now)!
        messages.append(contentsOf: [.init(id: id, text: "Text-\(id)", date: newDate)])
        objectWillChange.send()
    }

    func scrollToBottom() {
        let lastMessage = messages.last
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
        let lastMessage = messages.last
        let newDate = Calendar.current.date(byAdding: .day, value: 1, to: lastMessage?.date ?? .now)!
        let id = (lastMessage?.id ?? 0) + 1
        messages.append(contentsOf: [.init(id: id, text: "Added Text-\(id)", date: newDate)])
        scrollTo(id)
    }

    func addToTop() {
        let first = messages.first
        let previousDate = Calendar.current.date(byAdding: .day, value: -1, to: first?.date ?? .now)!
        let id = (first?.id ?? 0) - 1
        messages.insert(.init(id: id, text: "Added Text-\(id)", date: previousDate), at: 0)
        objectWillChange.send()
    }
}

struct ContentViewArray: View {
    var body: some View {
        NavigationSplitView {
            Text("SideBar")
        } content: {
            Text("Second")
        } detail: {
            DetailViewArray()
        }
    }
}

struct TextMessageRowArray: View {
    var message: Message
    let viewModel: ViewModelArray

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

struct DetailViewArray: View {
    var body: some View {
        ScrollViewReader { scrollView in
            ScrollViewContentArray(scrollView: scrollView)
        }
    }
}

struct ScrollViewContentArray: View {
    var scrollView: ScrollViewProxy
    @StateObject var viewModel = ViewModelArray()

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                if viewModel.isLoading {
                    Text(verbatim: "IsLoading")
                }
                ForEach(viewModel.messages) { message in
                    TextMessageRowArray(message: message, viewModel: viewModel)
                        .id(message.id)
                }
            }
            .background(geometryBackground)
            .padding(.bottom)
            .padding([.leading, .trailing])
        }
        .scrollDisabled(viewModel.disableScrolling)
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
        .onAppear {
            viewModel.scrollView = scrollView
            viewModel.scrollToBottom()
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
}

struct ContentViewArray_Previews: PreviewProvider {
    static var previews: some View {
        ContentViewArray()
    }
}

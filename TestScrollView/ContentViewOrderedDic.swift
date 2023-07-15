//
//  ContentView.swift
//  TestScrollView
//
//  Created by hamed on 7/5/23.
//

import SwiftUI
import OrderedCollections

class ViewModelOrderdDic: ObservableObject {
    var dictionary: OrderedDictionary<Date, [Message]> = [.now: (0...7000).map({Message(id: $0, text: "Text\($0)", date: .now)})]
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
        guard
            let firstKey = dictionary.keys.first,
            let firstOldItem = dictionary[firstKey]?.first
        else { return }
        let oldTopItemId = firstOldItem.id
        Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
            self.disableScrolling = true
            self.objectWillChange.send()
            let firstId = abs(oldTopItemId) + 1
            let endId = firstId + 20000
            let previousDate = Calendar.current.date(byAdding: .day, value: -1, to: firstOldItem.date)!
            let messages: [Message] = (firstId...endId).map({.init(id: -$0, text: "Added Text-\(-$0)", date: .now)}).sorted(by: {$0.id < $1.id})
            self.dictionary[previousDate] = messages
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
        guard let lastKey = dictionary.keys.sorted(by: {$0 < $1}).last else { return }
        let lastMessage = dictionary[lastKey]?.last
        let id = (lastMessage?.id ?? 0) + 1
        let newDate = Calendar.current.date(byAdding: .day, value: 1, to: lastMessage?.date ?? .now)!
        dictionary[newDate] = [.init(id: id, text: "Added Text-\(id)", date: newDate)]
        objectWillChange.send()
    }

    func scrollToBottom() {
        guard let lastKey = dictionary.keys.sorted(by: {$0 < $1}).last else { return }
        let lastMessage = dictionary[lastKey]?.last
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
        guard let lastKey = dictionary.keys.sorted(by: {$0 < $1}).last else { return }
        let lastMessage = dictionary[lastKey]?.last
        let newDate = Calendar.current.date(byAdding: .day, value: 1, to: lastMessage?.date ?? .now)!
        let id = (lastMessage?.id ?? 0) + 1
        dictionary[newDate] = [.init(id: id, text: "Addded Text-\(id)", date: newDate)]
        scrollTo(id)
    }

    func addToTop() {
        guard let firstKey = dictionary.keys.sorted(by: {$0 < $1}).first else { return }
        let firstMessage = dictionary[firstKey]?.first
        let previousDate = Calendar.current.date(byAdding: .day, value: -1, to: firstMessage?.date ?? .now)!
        let id = (firstMessage?.id ?? 0) - 1
        dictionary[previousDate] = [.init(id: id, text: "Added Text-\(id)", date: previousDate)]
        objectWillChange.send()
    }
}

struct ContentViewOrderedDic: View {
    var body: some View {
        NavigationSplitView {
            Text("SideBar")
        } content: {
            Text("Second")
        } detail: {
            DetailViewOrderedDictionary()
        }
    }
}

struct TextMessageRowOrderedDictionary: View {
    var message: Message
    let viewModel: ViewModelOrderdDic

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

struct DetailViewOrderedDictionary: View {
    var body: some View {
        ScrollViewReader { scrollView in
            ScrollViewContentArray(scrollView: scrollView)
        }
    }
}

struct ScrollViewContentOrderedDictionary: View {
    var scrollView: ScrollViewProxy
    @StateObject var viewModel = ViewModelOrderdDic()

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                if viewModel.isLoading {
                    Text(verbatim: "IsLoading")
                }
                ForEach(viewModel.dictionary.keys, id: \.self) { sectionKey in
                    Text(sectionKey.description)
                    ForEach(viewModel.dictionary[sectionKey] ?? []) { message in
                        TextMessageRowOrderedDictionary(message: message, viewModel: viewModel)
                            .id(message.id)
                    }
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

struct ContentViewOrderedDic_Previews: PreviewProvider {
    static var previews: some View {
        ContentViewOrderedDic()
    }
}

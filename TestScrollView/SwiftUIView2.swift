//
//  SwiftUIView2.swift
//  TestScrollView
//
//  Created by hamed on 7/13/23.
//

import SwiftUI

@available(iOS 17.0, *)
struct SwiftUIView2: View {
    @State var data: [String] = (0 ..< 25).map { String($0) }
    @State var dataID: String?

    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(data, id: \.self) { item in
                    ZStack {
                        Color.red
                        Text("\(item)")
                            .padding()
                            .background()

                    }
                    .frame(height: 100)
                    .scrollTransition(topLeading: .animated(.bouncy), bottomTrailing: .animated) { view, transition in
                        view
                            .offset(x: transition.isIdentity ? 0 : -600)
                            .rotationEffect(.radians(transition.value))
                    }
                }
            }
            .scrollTargetLayout()
        }
        .scrollPosition(id: $dataID)
        .scrollPosition(initialAnchor: .bottom)
        .safeAreaInset(edge: .bottom) {
            Text("\(Text("Scrolled").bold()) \(dataIDText)")
            Spacer()
            Button {
                dataID = data.first
            } label: {
                Label("Top", systemImage: "arrow.up")
            }
            Button {
                dataID = data.last
            } label: {
                Label("Bottom", systemImage: "arrow.down")
            }
            Menu {
                Button("Prepend") {
                    let next = String(data.count)
                    data.insert(next, at: 0)
                }
                Button("Append") {
                    let next = String(data.count)
                    data.append(next)
                }
                Button("Remove First") {
                    data.removeFirst()
                }
                Button("Remove Last") {
                    data.removeLast()
                }
            } label: {
                Label("More", systemImage: "ellipsis.circle")
            }
        }
    }

    var dataIDText: String {
        dataID.map(String.init(describing:)) ?? "None"
    }
}

#Preview {
    if #available(iOS 17.0, *) {
        SwiftUIView2()
    } else {
        EmptyView()
    }
}

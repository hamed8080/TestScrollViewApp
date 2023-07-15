//
//  SwiftUIView.swift
//  TestScrollView
//
//  Created by hamed on 7/13/23.
//

import SwiftUI

@available(iOS 17.0, *)
struct SwiftUIView: View {
    @State var data: [String] = (0 ..< 25).map { String($0) }
    @State var dataID: String?

    var body: some View {
        ScrollView {
            VStack {
                Text("Header")

                LazyVStack {
                    ForEach(data, id: \.self) { item in
                        Color.red
                            .frame(width: 100, height: 100)
                            .overlay {
                                Text("\(item)")
                                    .padding()
                                    .background()
                            }
                    }
                }
                .scrollTargetLayout()
            }
        }
        .scrollPosition(id: $dataID)
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
//                    Button("Batch Prepend") {
//                        let newDatas = (data.count ..< data.count + 6).map{"New Data \($0)"}
//                        newDatas.forEach { data in
//                            self.data.insert(data, at: 0)
//                        }
////                        data.insert(contentsOf: newDatas, at: 0) // Does not have any difference.
//                    }

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

struct SwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        if #available(iOS 17.0, *) {
            SwiftUIView()
        } else {
            EmptyView()
        }
    }
}

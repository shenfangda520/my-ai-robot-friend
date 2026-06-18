//
//  MeView.swift
//  阿默 —— “我”页：你自己的设定（让阿默知道在跟谁聊）
//

import SwiftUI

struct MeView: View {
    @ObservedObject var store: ChatStore
    private var palette: MoodPalette { store.mood.palette }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledField(label: "名字", text: $store.user.name, placeholder: "你叫什么")
                    LabeledField(label: "希望它怎么称呼你", text: $store.user.nickname, placeholder: "昵称/外号（可选）")
                    LabeledField(label: "性别", text: $store.user.gender, placeholder: "可选")
                    LabeledField(label: "年龄", text: $store.user.age, placeholder: "可选")
                    LabeledField(label: "职业 / 身份", text: $store.user.job, placeholder: "可选")
                } header: {
                    Text("你是谁")
                } footer: {
                    Text("\(store.persona.name)会据此认识你、用合适的称呼跟你说话。")
                }
                .glassRow()

                Section("关于你") {
                    TextField("爱好、性格、最近在忙的事、在意的人…",
                              text: $store.user.about, axis: .vertical)
                        .lineLimit(3...8)
                }
                .glassRow()
            }
            .glassForm(palette)
            .navigationTitle("我")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .onChange(of: store.user) { _, _ in store.saveUser() }
        }
    }
}

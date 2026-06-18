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
                    GlassPageHeader(
                        imageName: "AvatarHappy",
                        title: "让阿默认识你",
                        subtitle: "这些设定会影响称呼、语气和它主动关心你的方式。",
                        palette: palette
                    )
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 8, leading: 18, bottom: 8, trailing: 18))

                Section {
                    LabeledField(label: "名字", text: $store.user.name, placeholder: "你叫什么")
                    LabeledField(label: "希望它怎么称呼你", text: $store.user.nickname, placeholder: "昵称/外号（可选）")

                    Picker("性别", selection: $store.user.gender) {
                        Text("未选择").tag("")
                        ForEach(UserProfile.genderOptions, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.menu)
                    .formControlRow()

                    Picker("年龄", selection: $store.user.age) {
                        Text("未选择").tag("")
                        Text("保密").tag("保密")
                        ForEach(12...80, id: \.self) { Text("\($0) 岁").tag(String($0)) }
                    }
                    .pickerStyle(.navigationLink)
                    .formControlRow()

                    Picker("职业 / 身份", selection: $store.user.job) {
                        Text("未选择").tag("")
                        ForEach(UserProfile.jobOptions, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.menu)
                    .formControlRow()
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
                        .font(.system(size: 15))
                        .glassFieldBackground()
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

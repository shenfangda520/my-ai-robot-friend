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
            RobotPage(palette: palette) {
                SiriCommunicationHero(
                    title: "让\(store.persona.name)识别你",
                    subtitle: "像 Siri 记住你的偏好一样，这里决定它怎么称呼你、理解你，以及什么时候更懂你的语气。",
                    chips: [displayName, store.user.job.isEmpty ? "身份未设置" : store.user.job, "本机保存"],
                    palette: palette,
                    visual: .personSignal
                )

                SurfaceSection(title: "你的称呼", subtitle: "先让它知道正在和谁说话。") {
                    LabeledField(label: "名字", text: $store.user.name, placeholder: "你叫什么")
                    LabeledField(label: "称呼", text: $store.user.nickname, placeholder: "昵称/外号")
                }

                SurfaceSection(title: "个人信号", subtitle: "这些信息会参与它的语气判断。") {
                    MenuPickerRow(label: "性别", selection: $store.user.gender,
                                  options: UserProfile.genderOptions)
                    MenuPickerRow(label: "年龄", selection: $store.user.age,
                                  options: ["保密"] + (12...80).map(String.init),
                                  display: { $0 == "保密" ? "保密" : "\($0) 岁" })
                    MenuPickerRow(label: "职业 / 身份", selection: $store.user.job,
                                  options: UserProfile.jobOptions)
                }

                SurfaceSection(title: "关于你", subtitle: "\(store.persona.name)会用这些内容建立对你的长期印象。") {
                    TextField("爱好、性格、最近在忙的事、在意的人…",
                              text: $store.user.about, axis: .vertical)
                        .lineLimit(3...8)
                        .font(.system(size: 15))
                        .glassFieldBackground()
                }
            }
            .navigationTitle("我")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: store.user) { _, _ in store.saveUser() }
        }
    }

    private var displayName: String {
        if !store.user.nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return store.user.nickname
        }
        if !store.user.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return store.user.name
        }
        return "还没命名"
    }
}

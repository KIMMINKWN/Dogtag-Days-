//
//  OnboardingFlow.swift
//  훈련소 앱 - 온보딩 설문 + ID 발급 프로토타입
//
//  사용법:
//  1. Xcode에서 File > New > File... > SwiftUI View 로 새 파일 생성 (이름 아무거나)
//  2. 이 파일 내용을 통째로 붙여넣기 (또는 이 파일 자체를 프로젝트에 드래그해서 추가)
//  3. App 진입점(예: YourAppNameApp.swift)에서 WindowGroup 안의 ContentView() 를
//     OnboardingFlow() 로 바꾸면 바로 실행됨
//

import SwiftUI

// MARK: - Design Tokens

enum Palette {
    static let bg        = Color(hex: "#F5F3ED")
    static let ink        = Color(hex: "#262521")
    static let inkSoft    = Color(hex: "#5A5648")
    static let olive      = Color(hex: "#707C5C")
    static let oliveDark  = Color(hex: "#565F45")
    static let clay       = Color(hex: "#B5624B")
    static let line       = Color(hex: "#D9D4C7")
    static let card       = Color.white
}

extension Color {
    init(hex: String) {
        let s = hex.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        Scanner(string: s).scanHexInt64(&rgb)
        self.init(
            red: Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8) & 0xFF) / 255,
            blue: Double(rgb & 0xFF) / 255
        )
    }
}

// MARK: - Model

enum Branch: String, CaseIterable, Identifiable {
    case army, navy, airforce
    var id: String { rawValue }
    var label: String {
        switch self {
        case .army: return "육군"
        case .navy: return "해군"
        case .airforce: return "공군"
        }
    }
    var icon: String {
        switch self {
        case .army: return "shield.fill"
        case .navy: return "ferry.fill"
        case .airforce: return "airplane"
        }
    }
    var code: String {
        switch self {
        case .army: return "AR"
        case .navy: return "NV"
        case .airforce: return "AF"
        }
    }
}

enum ServiceStatus: String, CaseIterable, Identifiable {
    case active, publicDuty
    var id: String { rawValue }
    var label: String {
        switch self {
        case .active: return "현역"
        case .publicDuty: return "공익"
        }
    }
    var desc: String {
        switch self {
        case .active: return "18개월 복무"
        case .publicDuty: return "복무 기간 상이"
        }
    }
}

struct TraineeData {
    var name: String = ""
    var age: String = ""
    var branch: Branch? = nil
    var status: ServiceStatus? = nil
}

// MARK: - Root View

struct OnboardingFlow: View {
    @State private var step: Int = 0
    @State private var data = TraineeData()
    @State private var issuedId: String = ""
    private let totalSteps = 4

    var body: some View {
        ZStack {
            Palette.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                if step < totalSteps {
                    ProgressTicks(step: step, total: totalSteps)
                        .padding(.bottom, 24)

                    Group {
                        switch step {
                        case 0: NameAgeStep(data: $data)
                        case 1: BranchStep(data: $data)
                        case 2: StatusStep(data: $data)
                        default: ReviewStep(data: data)
                        }
                    }

                    Spacer()

                    HStack(spacing: 12) {
                        if step > 0 {
                            Button {
                                withAnimation { step -= 1 }
                            } label: {
                                Image(systemName: "chevron.left")
                                    .foregroundColor(Palette.inkSoft)
                                    .frame(width: 48, height: 48)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Palette.line, lineWidth: 1)
                                    )
                            }
                        }

                        Button {
                            if step == totalSteps - 1 {
                                issuedId = generateId()
                            }
                            withAnimation { step += 1 }
                        } label: {
                            HStack(spacing: 6) {
                                Text(step == totalSteps - 1 ? "ID 발급받기" : "다음")
                                    .font(.system(size: 15, weight: .semibold))
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(canProceed ? Palette.oliveDark : Palette.line)
                            .cornerRadius(8)
                        }
                        .disabled(!canProceed)
                    }
                } else {
                    IdCardView(data: data, issuedId: issuedId) {
                        withAnimation {
                            step = 0
                            data = TraineeData()
                        }
                    }
                }
            }
            .padding(24)
        }
        .font(.custom("Pretendard", size: 16))
    }

    private var canProceed: Bool {
        switch step {
        case 0: return !data.name.trimmingCharacters(in: .whitespaces).isEmpty && !data.age.isEmpty
        case 1: return data.branch != nil
        case 2: return data.status != nil
        default: return true
        }
    }

    private func generateId() -> String {
        let code = data.branch?.code ?? "XX"
        let rand = Int.random(in: 1000...9999)
        return "\(code)-\(rand)"
    }
}

// MARK: - Progress

struct ProgressTicks: View {
    let step: Int
    let total: Int
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<total, id: \.self) { i in
                Rectangle()
                    .fill(i <= step ? Palette.olive : Palette.line)
                    .frame(height: 3)
            }
        }
        .padding(.top, 12)
    }
}

// MARK: - Step 0: Name / Age

struct NameAgeStep: View {
    @Binding var data: TraineeData
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 4) {
                Text("훈련병 정보 등록")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Palette.ink)
                Text("가족에게 훈련 소식을 자동으로 전해드릴게요.")
                    .font(.system(size: 14))
                    .foregroundColor(Palette.inkSoft)
            }

            FieldLabel("이름") {
                TextField("홍길동", text: $data.name)
                    .textFieldStyle(TraineeFieldStyle())
            }
            FieldLabel("나이") {
                TextField("21", text: $data.age)
                    .keyboardType(.numberPad)
                    .textFieldStyle(TraineeFieldStyle())
            }
        }
    }
}

// MARK: - Step 1: Branch

struct BranchStep: View {
    @Binding var data: TraineeData
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 4) {
                Text("군종을 선택해주세요")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Palette.ink)
                Text("훈련 일정이 군종마다 달라요.")
                    .font(.system(size: 14))
                    .foregroundColor(Palette.inkSoft)
            }

            VStack(spacing: 12) {
                ForEach(Branch.allCases) { branch in
                    let selected = data.branch == branch
                    Button {
                        data.branch = branch
                    } label: {
                        HStack(spacing: 16) {
                            Image(systemName: branch.icon)
                                .font(.system(size: 20))
                            Text(branch.label)
                                .font(.system(size: 16, weight: .medium))
                            Spacer()
                            if selected {
                                Image(systemName: "checkmark")
                            }
                        }
                        .foregroundColor(selected ? .white : Palette.ink)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(selected ? Palette.olive : Palette.card)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(selected ? Palette.olive : Palette.line, lineWidth: 1)
                        )
                        .cornerRadius(8)
                    }
                }
            }
        }
    }
}

// MARK: - Step 2: Status

struct StatusStep: View {
    @Binding var data: TraineeData
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 4) {
                Text("복무 신분을 선택해주세요")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Palette.ink)
                Text("복무 기간 계산에 사용돼요.")
                    .font(.system(size: 14))
                    .foregroundColor(Palette.inkSoft)
            }

            VStack(spacing: 12) {
                ForEach(ServiceStatus.allCases) { status in
                    let selected = data.status == status
                    Button {
                        data.status = status
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(status.label)
                                    .font(.system(size: 16, weight: .medium))
                                Text(status.desc)
                                    .font(.system(size: 12))
                                    .foregroundColor(selected ? Color.white.opacity(0.85) : Palette.inkSoft)
                            }
                            Spacer()
                            if selected {
                                Image(systemName: "checkmark")
                            }
                        }
                        .foregroundColor(selected ? .white : Palette.ink)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(selected ? Palette.olive : Palette.card)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(selected ? Palette.olive : Palette.line, lineWidth: 1)
                        )
                        .cornerRadius(8)
                    }
                }
            }
        }
    }
}

// MARK: - Step 3: Review

struct ReviewStep: View {
    let data: TraineeData
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 4) {
                Text("입력 정보를 확인해주세요")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Palette.ink)
                Text("이 정보로 훈련 일정과 ID가 발급돼요.")
                    .font(.system(size: 14))
                    .foregroundColor(Palette.inkSoft)
            }

            VStack(spacing: 0) {
                ReviewRow(label: "이름", value: data.name)
                Divider().overlay(Palette.line)
                ReviewRow(label: "나이", value: data.age)
                Divider().overlay(Palette.line)
                ReviewRow(label: "군종", value: data.branch?.label ?? "-")
                Divider().overlay(Palette.line)
                ReviewRow(label: "신분", value: data.status?.label ?? "-")
            }
            .background(Palette.card)
            .overlay(
                RoundedRectangle(cornerRadius: 8).stroke(Palette.line, lineWidth: 1)
            )
            .cornerRadius(8)
        }
    }
}

struct ReviewRow: View {
    let label: String
    let value: String
    var body: some View {
        HStack {
            Text(label).font(.system(size: 14)).foregroundColor(Palette.inkSoft)
            Spacer()
            Text(value).font(.system(size: 14, weight: .medium)).foregroundColor(Palette.ink)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

// MARK: - ID Card (Result)

struct IdCardView: View {
    let data: TraineeData
    let issuedId: String
    let onRestart: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 6) {
                    Text("REGISTERED")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .tracking(2)
                        .foregroundColor(Palette.olive)
                    Text("ID가 발급됐어요")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Palette.ink)
                }
                .padding(.top, 12)

                // Dog-tag card
                VStack(alignment: .leading, spacing: 32) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("TRAINEE")
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .tracking(2)
                                .foregroundColor(Color(hex: "#8B8776"))
                            Text(data.name.isEmpty ? "훈련병" : data.name)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                            Text("\(data.branch?.label ?? "") · \(data.age)세")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(Color(hex: "#B8B4A3"))
                        }
                        Spacer()
                        Image(systemName: "person.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Color(hex: "#B8B4A3"))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(issuedId)
                            .font(.system(size: 30, weight: .bold, design: .monospaced))
                            .tracking(1.5)
                            .foregroundColor(Palette.clay)
                        Text("이 ID로 가족이 소식을 구독할 수 있어요")
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "#7A7666"))
                    }
                }
                .padding(24)
                .background(Palette.ink)
                .cornerRadius(20)

                // QR invite
                HStack(spacing: 16) {
                    Image(systemName: "qrcode")
                        .font(.system(size: 32))
                        .foregroundColor(Palette.ink)
                        .padding(12)
                        .background(Palette.bg)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Palette.line, lineWidth: 1))
                        .cornerRadius(8)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("QR로 초대하기")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Palette.ink)
                        Text("가족·지인이 스캔하면 바로 구독돼요")
                            .font(.system(size: 12))
                            .foregroundColor(Palette.inkSoft)
                    }
                    Spacer()
                }
                .padding(16)
                .background(Palette.card)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Palette.line, lineWidth: 1))
                .cornerRadius(8)

                Button {
                    // TODO: 실제 공유 시트 연결 (ShareLink 또는 UIActivityViewController)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                        Text("가족에게 공유하기")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Palette.oliveDark)
                    .cornerRadius(8)
                }

                Button("처음부터 다시") {
                    onRestart()
                }
                .font(.system(size: 12))
                .foregroundColor(Palette.inkSoft)
                .padding(.bottom, 12)
            }
        }
    }
}

// MARK: - Shared UI Helpers

struct FieldLabel<Content: View>: View {
    let title: String
    let content: Content
    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 11, design: .monospaced))
                .tracking(1)
                .foregroundColor(Palette.inkSoft)
            content
        }
    }
}

struct TraineeFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Palette.card)
            .overlay(
                RoundedRectangle(cornerRadius: 8).stroke(Palette.line, lineWidth: 1)
            )
            .cornerRadius(8)
            .foregroundColor(Palette.ink)
    }
}

// MARK: - Preview

#Preview {
    OnboardingFlow()
}

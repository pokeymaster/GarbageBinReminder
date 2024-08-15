import SwiftUI

struct SettingsView: View {
    @State private var selectedTime = Date() // 用 @State 存储用户界面中的时间
    @State private var selectedDay = 1 // 用 @State 存储用户选择的天数
    @State private var showingConfirmation = false // 显示确认信息的状态
    @State private var showingSmartReminderSuggestion = false // 显示智能提醒建议的状态

    @AppStorage("selectedTimesString", store: UserDefaults.standard) private var selectedTimesString: String = "" // 用于存储所有保存的时间字符串
    @AppStorage("selectedTimeInterval", store: UserDefaults.standard) private var selectedTimeInterval: TimeInterval = Date().timeIntervalSince1970
    @AppStorage("selectedLanguage", store: UserDefaults.standard) private var selectedLanguage = "en"
    @AppStorage("widgetTheme", store: UserDefaults.standard) private var widgetTheme: String = "Light"
    @AppStorage("selectedSound", store: UserDefaults.standard) private var selectedSound = "Default"
    @AppStorage("selectedDay", store: UserDefaults.standard) private var storedSelectedDay: Int = 1
    
    let languages = ["en": "English", "zh": "中文", "es": "Español"]
    let themes = ["Light", "Dark"]
    let sounds = ["Default", "Chime", "Alert", "Silent"]
    let daysOfWeek = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    
    var body: some View {
        Form {
            Section(header: Text(localizedString("Notification Time"))) {
                DatePicker(localizedString("Select Time"), selection: $selectedTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(WheelDatePickerStyle())
                
                Picker(localizedString("Select Day"), selection: $selectedDay) {
                    ForEach(1..<8) { index in
                        Text(localizedString(daysOfWeek[index - 1])).tag(index)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                
                Button(action: {
                    saveSettings()
                    scheduleCustomNotification()
                    showingConfirmation = true
                    analyzeUserHabit() // 在保存设置后分析用户习惯
                }) {
                    Text(localizedString("Confirm Time"))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .alert(isPresented: $showingConfirmation) {
                    Alert(title: Text(localizedString("Settings Saved")), message: Text(localizedString("Your notification settings have been saved successfully.")), dismissButton: .default(Text("OK")))
                }
                .alert(isPresented: $showingSmartReminderSuggestion) {
                    Alert(title: Text(localizedString("Smart Reminder Suggestion")), message: Text(localizedString("We noticed you often set reminders around this time. Would you like to set this as your default reminder time?")), primaryButton: .default(Text("Yes"), action: {
                        selectedTimeInterval = mostCommonTimeInterval(in: <#[TimeInterval]#>)
                    }), secondaryButton: .cancel())
                }
            }
            
            Section(header: Text(localizedString("Language"))) {
                Picker(localizedString("Select Language"), selection: $selectedLanguage) {
                    ForEach(languages.keys.sorted(), id: \.self) { key in
                        Text(languages[key] ?? key).tag(key)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: selectedLanguage) { newLanguage in
                    updateLanguage(to: newLanguage)
                }
            }
            
            Section(header: Text(localizedString("Theme"))) {
                Picker(localizedString("Select Theme"), selection: $widgetTheme) {
                    ForEach(themes, id: \.self) {
                        Text(localizedString($0))
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: widgetTheme) { newTheme in
                    applyTheme(newTheme)
                }
            }
            
            Section(header: Text(localizedString("Notification Sound"))) {
                Picker(localizedString("Select Sound"), selection: $selectedSound) {
                    ForEach(sounds, id: \.self) {
                        Text(localizedString($0))
                    }
                }
            }
        }
        .navigationTitle(localizedString("Settings"))
        .onAppear {
            selectedTime = Date(timeIntervalSince1970: selectedTimeInterval)
            selectedDay = storedSelectedDay
            applyTheme(widgetTheme)
        }
    }
    
    // 保存设置到 @AppStorage，并记录提醒时间
    func saveSettings() {
        selectedTimeInterval = selectedTime.timeIntervalSince1970
        storedSelectedDay = selectedDay
        
        // 将时间记录为字符串，并存储在 AppStorage 中
        let timeIntervals = selectedTimesString.split(separator: ",").compactMap { TimeInterval($0) }
        var updatedTimeIntervals = timeIntervals
        updatedTimeIntervals.append(selectedTimeInterval)
        selectedTimesString = updatedTimeIntervals.map { String($0) }.joined(separator: ",")
    }
    
    // 分析用户习惯，建议智能提醒
    func analyzeUserHabit() {
        let timeIntervals = selectedTimesString.split(separator: ",").compactMap { TimeInterval($0) }
        let mostCommonInterval = mostCommonTimeInterval(in: timeIntervals)
        
        // 如果某个时间段出现次数较多，提示用户设置为默认时间
        if timeIntervals.filter({ abs($0 - mostCommonInterval) < 600 }).count >= 3 { // 600秒 = 10分钟内的设置算相同
            showingSmartReminderSuggestion = true
        }
    }
    
    // 找出用户最常用的时间段
    func mostCommonTimeInterval(in intervals: [TimeInterval]) -> TimeInterval {
        let counts = intervals.reduce(into: [TimeInterval: Int]()) { counts, interval in
            let key = interval - (interval.truncatingRemainder(dividingBy: 600)) // 每10分钟为一个时间段
            counts[key, default: 0] += 1
        }
        return counts.max(by: { $0.value < $1.value })?.key ?? selectedTimeInterval
    }
    
    func scheduleCustomNotification() {
        let notificationContent = UNMutableNotificationContent()
        notificationContent.title = localizedString("Garbage Bin Reminder")
        notificationContent.body = localizedString("Remember to place the correct bins outside.")
        notificationContent.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "\(selectedSound).caf"))
        
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: selectedTime)
        let minute = calendar.component(.minute, from: selectedTime)
        
        var dateComponents = DateComponents()
        dateComponents.weekday = selectedDay
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "CustomWeeklyBinReminder-\(selectedDay)", content: notificationContent, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Notification scheduling error: \(error)")
            }
        }
    }
    
    func applyTheme(_ theme: String) {
        let window = UIApplication.shared.windows.first
        if theme == "Dark" {
            window?.overrideUserInterfaceStyle = .dark
        } else {
            window?.overrideUserInterfaceStyle = .light
        }
    }
    
    // 更新应用语言
    func updateLanguage(to language: String) {
        UserDefaults.standard.set([language], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
        // 应用需要重启以应用新的语言设置
    }
    
    // 从 Localizable.strings 获取本地化字符串
    func localizedString(_ key: String) -> String {
        return Bundle.main.localizedString(forKey: key, value: nil, table: nil)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}

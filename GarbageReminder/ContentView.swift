import SwiftUI
import UserNotifications
import AVFoundation

struct ContentView: View {
    @State private var binMessage: String = ""
    @State private var showMessage = false
    @State private var audioPlayer: AVAudioPlayer?
    @AppStorage("selectedTimeInterval", store: UserDefaults(suiteName: "group.com.individual.GarbageBinReminder")) private var selectedTimeInterval: TimeInterval = Date().timeIntervalSince1970
    @AppStorage("selectedDay", store: UserDefaults(suiteName: "group.com.individual.GarbageBinReminder")) private var selectedDay: Int = 1

    let daysOfWeek = [
        NSLocalizedString("Sunday", comment: ""),
        NSLocalizedString("Monday", comment: ""),
        NSLocalizedString("Tuesday", comment: ""),
        NSLocalizedString("Wednesday", comment: ""),
        NSLocalizedString("Thursday", comment: ""),
        NSLocalizedString("Friday", comment: ""),
        NSLocalizedString("Saturday", comment: "")
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.green.opacity(0.7)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    Text(NSLocalizedString("Garbage Bin Reminder", comment: ""))
                        .font(.largeTitle)
                        .fontWeight(.heavy)
                        .foregroundColor(.white)
                        .padding(.top, 50)
                    
                    Spacer()
                    
                    VStack {
                        if showMessage {
                            Text(binMessage)
                                .font(.title)
                                .fontWeight(.bold)
                                .padding()
                                .foregroundColor(.white)
                                .transition(.opacity)
                            
                            Text("\(NSLocalizedString("Reminder Day", comment: "")): \(daysOfWeek[selectedDay - 1])")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(.top, 10)
                            
                            Text("\(NSLocalizedString("Reminder Time", comment: "")): \(formattedTime)")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(.top, 5)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(20)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 50)
                    
                    Spacer()

                    NavigationLink(destination: SettingsView()) {
                        Text(NSLocalizedString("Settings", comment: ""))
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.orange)
                            .cornerRadius(10)
                            .shadow(radius: 10)
                    }
                    .padding(.bottom, 20)
                    .scaleEffect(showMessage ? 1 : 0.95)
                    .animation(.easeIn(duration: 0.3))
                    .onTapGesture {
                        playSound("click")
                    }
                }
            }
            .onAppear {
                requestNotificationPermission()
                updateBinMessage()
                scheduleWeeklyNotification()
                showMessage = true // 确保 showMessage 被设置为 true
            }
            .navigationTitle(NSLocalizedString("Home", comment: ""))
        }
    }
    
    func playSound(_ soundName: String) {
        if let sound = Bundle.main.path(forResource: soundName, ofType: "mp3") {
            audioPlayer = try? AVAudioPlayer(contentsOf: URL(fileURLWithPath: sound))
            audioPlayer?.play()
        }
    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print(NSLocalizedString("Notification permission error", comment: "") + ": \(error)")
            }
        }
    }
    
    func updateBinMessage() {
        let calendar = Calendar.current
        let currentDate = Date()
        let weekOfYear = calendar.component(.weekOfYear, from: currentDate)
        
        if weekOfYear % 2 == 0 {
            binMessage = NSLocalizedString("This Week: Recyclable Waste & Green Waste", comment: "")
        } else {
            binMessage = NSLocalizedString("This Week: General Waste & Green Waste", comment: "")
        }
    }
    
    func scheduleWeeklyNotification() {
        let notificationContent = UNMutableNotificationContent()
        notificationContent.title = NSLocalizedString("Garbage Bin Reminder", comment: "")
        notificationContent.body = binMessage
        notificationContent.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.weekday = selectedDay
        let selectedDate = Date(timeIntervalSince1970: selectedTimeInterval)
        let calendar = Calendar.current
        dateComponents.hour = calendar.component(.hour, from: selectedDate)
        dateComponents.minute = calendar.component(.minute, from: selectedDate)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "WeeklyBinReminder-\(UUID().uuidString)", content: notificationContent, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print(NSLocalizedString("Notification scheduling error", comment: "") + ": \(error)")
            }
        }
    }
    
    private var formattedTime: String {
        let date = Date(timeIntervalSince1970: selectedTimeInterval)
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

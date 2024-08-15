import WidgetKit
import SwiftUI

enum WidgetTheme: String, CaseIterable, Identifiable {
    case light = "Light"
    case dark = "Dark"
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        }
    }
}

struct GarbageBinWidgetEntryView: View {
    var entry: SimpleEntry
    @AppStorage("widgetOpacity") private var widgetOpacity: Double = 0.8
    @AppStorage("widgetTheme") private var widgetTheme: String = WidgetTheme.light.rawValue
    
    var body: some View {
        ZStack {
            // 背景视图
            backgroundView
                .opacity(widgetOpacity)
                .edgesIgnoringSafeArea(.all)
            
            VStack(alignment: .center, spacing: 8) {
                // 标题
                Text("Garbage Bin Reminder")
                    .font(.system(size: 16, weight: .bold, design: .default))
                    .foregroundColor(fontColor)
                    .padding(.top, 8)
                    .shadow(radius: 1)
                
                // 垃圾桶类型信息
                Text(entry.binMessage)
                    .font(.system(size: 18, weight: .semibold, design: .default))
                    .foregroundColor(fontColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.5)
                    .padding()
                    .background(binMessageBackgroundColor)
                    .cornerRadius(10)
                    .shadow(radius: 3)
            }
            .padding()
        }
        .background(Color.clear) // 确保背景透明，避免白边
    }
    
    private var backgroundView: some View {
        let theme = WidgetTheme(rawValue: widgetTheme) ?? .light
        
        switch theme {
        case .light:
            return LinearGradient(
                gradient: Gradient(colors: [Color(red: 220/255, green: 240/255, blue: 255/255), Color(red: 245/255, green: 245/255, blue: 245/255)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .dark:
            return LinearGradient(
                gradient: Gradient(colors: [Color(red: 15/255, green: 30/255, blue: 60/255), Color(red: 45/255, green: 15/255, blue: 75/255)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var binMessageBackgroundColor: Color {
        let theme = WidgetTheme(rawValue: widgetTheme) ?? .light
        return theme == .light ? Color(red: 173/255, green: 216/255, blue: 230/255).opacity(0.7) : Color(red: 15/255, green: 30/255, blue: 60/255).opacity(0.7)
    }
    
    private var fontColor: Color {
        let theme = WidgetTheme(rawValue: widgetTheme) ?? .light
        return theme == .light ? Color(red: 60/255, green: 60/255, blue: 60/255) : .white
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let binMessage: String
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), binMessage: "Loading...")
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        let entry = SimpleEntry(date: Date(), binMessage: getBinMessage())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        var entries: [SimpleEntry] = []
        let currentDate = Date()
        
        for hourOffset in 0..<24 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate, binMessage: getBinMessage())
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }

    func getBinMessage() -> String {
        let calendar = Calendar.current
        let currentDate = Date()
        let weekOfYear = calendar.component(.weekOfYear, from: currentDate)
        
        if weekOfYear % 2 == 0 {
            return "Recyclable Waste & Green Waste"
        } else {
            return "General Waste & Green Waste"
        }
    }
}


struct GarbageBinWidget: Widget {
    let kind: String = "GarbageBinWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            GarbageBinWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Garbage Bin Reminder")
        .description("Displays the type of garbage bin to be placed outside this week.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct GarbageBinWidget_Previews: PreviewProvider {
    static var previews: some View {
        GarbageBinWidgetEntryView(entry: SimpleEntry(date: Date(), binMessage: "Recyclable Waste & Green Waste"))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}

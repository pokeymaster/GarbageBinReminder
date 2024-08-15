import ActivityKit
import WidgetKit
import SwiftUI

// 定义 Live Activity 的属性
struct GarbageBinAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // 定义内容状态，这些状态会随着 Live Activity 的更新而变化
        var binMessage: String
    }

    // 定义活动的恒定属性
    var title: String
}

struct GarbageBinWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: GarbageBinAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text(context.attributes.title)
                Text(context.state.binMessage)
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom")
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T")
            } minimal: {
                Text("Min")
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

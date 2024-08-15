//
//  GarbageBinWidgetBundle.swift
//  GarbageBinWidget
//
//  Created by Yudong Chen on 15/8/2024.
//

import WidgetKit
import SwiftUI

@main
struct GarbageBinWidgetBundle: WidgetBundle {
    var body: some Widget {
        GarbageBinWidget()
        GarbageBinWidgetLiveActivity()
    }
}

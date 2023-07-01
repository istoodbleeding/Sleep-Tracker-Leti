import Foundation
import SwiftUI
import Charts

struct ChartView: View {

    let data: [SavingsDataPoint]

    var body: some View {
        VStack {
            Chart {
                ForEach(Array(data.enumerated()), id: \.offset) { index, element in
                    BarMark(x: .value("month", element.month), y: .value("value", element.value))
                        .foregroundStyle(index % 2 == 0 ? Color.lightButton : Color.lightButton)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisValueLabel()
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic) { value in
                    AxisValueLabel() {
                        if let intValue = value.as(Int.self) {
                            if intValue < 1000 {
                                Text("\(intValue)")
                                    .font(.body).foregroundColor(.dirtyWhite)
                            } else {
                                Text("\(intValue/1000)\(intValue == 0 ? "" : "k")")
                                    .font(.body).foregroundColor(.dirtyWhite)
                            }
                        }
                    }
                }
            }
        }
    }

}
struct SpendingScreen: View {

    @State var selectedTab = "Weekly"
    @State var tabs = ["Weekly", "Daily"]
    var chartData: [ String : [SavingsDataPoint]]
    
    init(chartData: [ String : [SavingsDataPoint]]) {
        self.chartData = chartData
        self.selectedTab = selectedTab
        self.tabs = tabs
        
    }
    var body: some View {
        VStack(alignment: .leading) {

            VStack{

                SegementedPicker(selected: $selectedTab, options: tabs)
                    .padding()

                ChartView(data: chartData[selectedTab]!)
                    .frame(minHeight: 200)
                    .padding()
                    .animation(.easeInOut, value: selectedTab)

                
            }
        }
    }

}



struct SegementedPicker: View {

    @Binding var selected: String
    let options: [String]
    @Namespace var underline

    var body: some View {
        VStack(alignment: .leading) {
            HStack(spacing: 30) {
                ForEach(options, id: \.self) { option in
                    VStack {
                        Button {
                            withAnimation {
                                selected = option
                            }
                        } label: {
                            VStack(alignment: .leading) {
                                Text(option)
                                    .foregroundColor(selected == option ? .primary : .secondary)
                            }
                        }

                        ZStack {
                            Rectangle().fill(Color.primary)
                                .frame(height: 1)
                                .opacity(0)

                            if selected == option {
                                Rectangle().fill(Color.primary)
                                    .frame(height: 1)
                                    .matchedGeometryEffect(id: "option", in: underline)
                            }
                        }

                    }
                    .fixedSize()
                }
            }
            Rectangle().frame(height: 1).foregroundStyle(Color.secondary.opacity(0.2))
                .offset(y: -9)
        }
    }

}

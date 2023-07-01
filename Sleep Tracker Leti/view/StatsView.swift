
import UniformTypeIdentifiers
import NotificationCenter
import Combine
import SwiftUI
import CoreData
import CoreLocation

struct StatsView: View {
    @Environment(\.managedObjectContext) var viewContext
    var demoData: [Double] = [8, 2, 4, 6, 12, 9, 2]
    @StateObject  var viewModel = StatsViewModel()
    let heights: [CGFloat] = [104, 58, 94, 122, 109, 72, 149]
    @State private var showingExporter = false
    @State var sleep = Sleep()
    @State var isEditVisible = false
    let calendar = Calendar.current
    @State var today = Date()
    var body: some View {
        ZStack {
            BackgroundView()
            VStack(alignment: .leading, spacing: 30) {
                Spacer().frame(height: 10)
                HStack{
                    
                    Text("Statistics")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.dirtyWhite)
                        .font(.montserrat(24))
                    Text("                      ")
                    Button("Export CSV"){
                        showingExporter = true}.fileExporter(isPresented: $showingExporter, document: CSVFile(initialText: viewModel.createExportString()), contentType: UTType.commaSeparatedText) { result in
                            switch result {
                            case .success(let url):
                                print("Saved to \(url)")
                            case .failure(let error):
                                print(error.localizedDescription)
                            }
                        }.foregroundColor(.dirtyWhite )
                }
                .overlay(
                                    Button("Edit") {
                                        viewModel.isEditVisible.toggle()
                                    }
                                    .foregroundColor(.dirtyWhite)
                                    .padding(.trailing)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                    .padding(.top, 65)
                                    .padding(.trailing, 10)
                                    , alignment: .topTrailing
                                )
                VStack(alignment: .leading) {
                  
                    ZStack {
                        SpendingScreen(chartData: viewModel.chartData).frame(width: 350, height: 300)
                        
                        
                        
                    }
                    
                }

                Spacer()
            }
            
            SleepListEditedView(viewModel: viewModel)
            
            
        }.onAppear{
            viewModel.fetchSleepsLastWeek()
            viewModel.fetchSleepsForDayIntervalsLast24Hours()
        }
    }
   
}


struct CSVFile: FileDocument {
    // tell the system we support only plain text
    static var readableContentTypes = [UTType.commaSeparatedText]
    static var writableContentTypes = [UTType.commaSeparatedText]
    
    // by default our document is empty
    var text = ""
    
    // a simple initializer that creates new, empty documents
    init(initialText: String = "") {
        text = initialText
    }
    
    // this initializer loads data that has been saved previously
    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            text = String(decoding: data, as: UTF8.self)
        }
    }
    
    // this will be called when the system wants to write our data to disk
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = Data(text.utf8)
        return FileWrapper(regularFileWithContents: data)
    }
}

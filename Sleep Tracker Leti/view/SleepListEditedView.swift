import SwiftUI
import CoreData

struct SleepListEditedView: View {
    @ObservedObject var viewModel = SleepListEditedViewModel()
    var statsViewModel : StatsViewModel
    @ObservedObject var appViewModel = SleepAppViewModel()
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
    let calendar = Calendar.current
    var dateComponents = DateComponents()
    init(viewModel: StatsViewModel){
        self.statsViewModel = viewModel
    }
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [.darkPurpleBackground, .darkPurpleBackground]), startPoint: .center, endPoint: .bottom)
                .ignoresSafeArea().opacity(statsViewModel.isEditVisible ? 1.0 : 0.0)
            StarsBackground().opacity(statsViewModel.isEditVisible ? 1.0 : 0.0)
            
            VStack {
                Spacer()
                HStack {
                    Text("Sleeps")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.dirtyWhite)
                        .font(.montserrat(20))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding([.top, .leading], 30)
                    Spacer()
                    Button("Close") {
                        statsViewModel.isEditVisible.toggle()
                        
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.top, 30)
                    .padding(.trailing, 50)
                }
                .padding(.top, 30.0)
                .listRowBackground(Color.darkPurpleBackground)
                List {
                    ForEach(viewModel.sleeps.indices, id: \.self) { index in
                        Section {
                            HStack {
                                Text("Sleep:  \(dateFormatter.string(from: (viewModel.sleeps[index].sleepArray.first?.begin)!)) \n             \(dateFormatter.string(from: (viewModel.sleeps[index].sleepArray.last?.end)!))")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.leading, 20)
                                Spacer()
                                Button("edit") {
                                    viewModel.sleeps[index].edited = false
                                    viewModel.viewContext.saveContext()
                                    appViewModel.notEditedSleeps = appViewModel.fetchSleepsWithEditStatusFalse()
                                }
                                .padding([.trailing], 30)
                            }
                            .frame(height: 100)
                            .listRowBackground(Color.darkPurpleBackground)
                            .background(Color.lightPurpleBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                        }
                        .frame(height: 100) // Увеличьте значение высоты секции
                    }
                }
                .listStyle(PlainListStyle())
                .frame(maxHeight: .infinity)
                
                Spacer()
            }
            .ignoresSafeArea(.all)
            .opacity(statsViewModel.isEditVisible ? 1.0 : 0.0)
            .listRowBackground(Color.darkPurpleBackground)
            .frame(maxWidth: UIScreen.main.bounds.width , maxHeight: UIScreen.main.bounds.height)
            ForEach(appViewModel.notEditedSleeps){ sleep in
                if sleep.edited == false {
                    SleepEditorView(sleep: sleep, appViewModel: appViewModel).onDisappear{
                        statsViewModel.fetchSleepsLastWeek()
                        statsViewModel.fetchSleepsForDayIntervalsLast24Hours()
                    }
                }
            }
        }
        .listRowBackground(Color.darkPurpleBackground)
    }
}



class SleepListEditedViewModel: ObservableObject {
    @Published var biggestEndDate = Date(timeIntervalSince1970: 0)
    @Published var smallestBeginDate = Date()
    let viewContext = PersistenceController.shared.viewContext
    @Published var sleeps: [Sleep] = []
    @Published var isAddVisible = false
    @Published var isViewVisible = false
    @Published var selectedSleep = 0
   
    let dateFormatter = DateFormatter()
    
    @Published var sleepIntervalsTemp: [SleepIntervalTemp] = []
    init (){
        fetchSortedSleepData()
    }
    
    func fetchSortedSleepData() {
        let request: NSFetchRequest<Sleep> = Sleep.fetchRequest()
        
        do {
            let sleeps = try self.viewContext.fetch(request)
            
            // Сортируем Sleep объекты в памяти
            self.sleeps = sleeps.sorted { (sleep1, sleep2) -> Bool in
                guard let begin1 = sleep1.sleepArray.first?.begin,
                      let begin2 = sleep2.sleepArray.first?.begin else {
                    // Если одного из интервалов нет, мы просто считаем, что sleep1 < sleep2
                    return true
                }
                
                // Возвращаем результат сравнения времени начала первого интервала
                return begin1 < begin2
            }
        } catch let error {
            print("Failed to fetch Sleep objects: \(error.localizedDescription)")
        }
    }
    
    
}

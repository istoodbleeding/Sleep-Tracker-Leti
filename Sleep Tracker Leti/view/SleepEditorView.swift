import SwiftUI
import CoreData

struct SleepEditorView: View {
    @ObservedObject var viewModel: SleepEditorViewModel
    var appViewModel: SleepAppViewModel
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
    var sleep: Sleep
    let calendar = Calendar.current
    var dateComponents = DateComponents()
    
    
    init(sleep: Sleep, appViewModel: SleepAppViewModel){
        self.appViewModel = appViewModel
        self.sleep = sleep
        self.viewModel = SleepEditorViewModel(sleep: sleep )
    }
    var body: some View {
        
        ZStack{
            LinearGradient(gradient: Gradient(colors: [.darkPurpleBackground, .darkPurpleBackground]), startPoint: .center, endPoint: .bottom)
                .ignoresSafeArea().opacity(viewModel.isAddVisible ? 0.0 : 1.0)
            StarsBackground().opacity(viewModel.isAddVisible ? 0.0 : 1.0)
            VStack {
                HStack {
                    Text("Sleep Intervals")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.dirtyWhite)
                        .font(.montserrat(20))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.all, 20)
                        .listRowInsets(EdgeInsets(top: 10, leading: 10, bottom: 0, trailing: 10)) // Apply insets to round the corners
                    Spacer()
                    Button("Add") {
                        viewModel.setSleepInterval()
                        viewModel.isAddVisible.toggle()
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.top, 20)
                    .padding(.trailing, 30)
                }
                .listRowBackground(Color.darkPurpleBackground)
                Text("Sleep from: \(viewModel.sleepIntervalsTemp.first != nil ? viewModel.dateFormatter.string(from: viewModel.sleepIntervalsTemp.first!.begin ?? Date()) : "N/A") \n to \(viewModel.sleepIntervalsTemp.last != nil ? viewModel.dateFormatter.string(from: viewModel.sleepIntervalsTemp.last!.end ?? Date()) : "N/A")")
                    .font(.system(size: 18, weight: .light))
                    .foregroundColor(.dirtyWhite)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding([.leading, .bottom, .trailing], 20)
                List {
                    ForEach(viewModel.sleepIntervalsTemp.indices, id: \.self) { index in
                        Section {
                            HStack {
                                Text("Begin:")
                                Spacer()
                                DatePicker("", selection: Binding(get: {
                                    self.viewModel.sleepIntervalsTemp[index].begin
                                }, set: { newValue in
                                    self.viewModel.sleepIntervalsTemp[index].begin = newValue
                                    viewModel.checkOverlappingIntervals()
                                }), in: viewModel.biggestEndDate...viewModel.sleepIntervalsTemp.last!.end)
                                .labelsHidden()
                                .datePickerStyle(.compact)
                            }
                            .listRowBackground(Color.darkPurpleBackground)
                            .padding()
                            .background(Color.lightPurpleBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 15 ))
                        
                            
                            HStack {
                                Text("End: ")
                                Spacer()
                                DatePicker("", selection: Binding(get: {
                                    self.viewModel.sleepIntervalsTemp[index].end
                                }, set: { newValue in
                                    self.viewModel.sleepIntervalsTemp[index].end = newValue
                                    viewModel.checkOverlappingIntervals()
                                }), in: viewModel.sleepIntervalsTemp.first!.begin...viewModel.smallestBeginDate)
                                .labelsHidden()
                                .datePickerStyle(.compact)
                            }
                            .listRowBackground(Color.darkPurpleBackground)
                            .padding()
                            .background(Color.lightPurpleBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                            
                            
                            Spacer()
                        }
                        .listSectionSeparatorTint(.darkPurpleBackground)
                            .listRowSeparatorTint(.darkPurpleBackground)
                    .listRowInsets(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10)) // Apply insets to round the corners
                        .listRowBackground(Color.darkPurpleBackground)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                   Button(action: {
                                       if viewModel.sleepIntervalsTemp.count > 1 {
                                           viewModel.sleepIntervalsTemp.remove(at: index)
                                       }
                                   }) {
                                       Image(systemName: "trash")
                                           .foregroundColor(.red)
                                   }
                               }
                    }
                }
                .listStyle(PlainListStyle())
                .frame(maxHeight: .infinity)
           

                HStack{
                    Spacer()
                    Button(action: {
                        viewModel.saveSleep(sleep: sleep)
                        appViewModel.notEditedSleeps = appViewModel.fetchSleepsWithEditStatusFalse()
                        viewModel.isViewVisible.toggle()
                    }) {
                        Text("Save")
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 20)
                            .background(Color.lightButton)
                            .cornerRadius(15)
                    }
                    Spacer()
                    Button(action: {
                        viewModel.deleteSleep(sleep: sleep)
                        viewModel.isViewVisible.toggle()
                    }) {
                        Text("Delete")
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 20)
                            .background(Color.lightButton)
                            .cornerRadius(15)
                    }
                    Spacer()
                }
                .padding(.vertical, 30.0)
                
            }
            .opacity(viewModel.isAddVisible ? 0.0 : 1.0)
            .listRowBackground(Color.darkPurpleBackground)
            .frame(maxWidth: UIScreen.main.bounds.width , maxHeight: UIScreen.main.bounds.height)
            

            LinearGradient(gradient: Gradient(colors: [.darkPurpleBackground, .darkPurpleBackground]), startPoint: .center, endPoint: .bottom)
                .ignoresSafeArea().opacity(viewModel.isAddVisible ? 1.0 : 0.0)
            StarsBackground().opacity(viewModel.isAddVisible ? 1.0 : 0.0)
            VStack{
                HStack {
                    Text("Add Sleep Interval")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.dirtyWhite)
                        .font(.montserrat(20))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.all, 20)
                        .listRowInsets(EdgeInsets(top: 10, leading: 10, bottom: 0, trailing: 10)) // Apply insets to round the corners
                    Spacer()
                   
                }
                .listRowBackground(Color.darkPurpleBackground)
                Text("Sleep from: \(viewModel.sleepIntervalsTemp.first != nil ? viewModel.dateFormatter.string(from: viewModel.sleepIntervalsTemp.first!.begin ?? Date()) : "N/A") \n to \(viewModel.sleepIntervalsTemp.last != nil ? viewModel.dateFormatter.string(from: viewModel.sleepIntervalsTemp.last!.end ?? Date()) : "N/A")")
                    .font(.system(size: 18, weight: .light))
                    .foregroundColor(.dirtyWhite)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding([.leading, .bottom, .trailing], 20)

                List{
                    Section(){
                        HStack {
                            Text("Begin: ")
                            Spacer()
                            DatePicker("", selection: Binding(get: {
                                viewModel.sleepInterval.begin
                            }, set: { newValue in
                                viewModel.sleepInterval.begin = newValue
                            }), in: viewModel.biggestEndDate...viewModel.sleepInterval.end, displayedComponents: [.date, .hourAndMinute])
                            .labelsHidden()
                           
                        }
                        .listRowBackground(Color.darkPurpleBackground)
                        .padding()
                        .background(Color.lightPurpleBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 15 ))
                        HStack {
                            Text("End: ")
                            Spacer()
                            DatePicker("", selection: Binding(get: {
                                viewModel.sleepInterval.end
                            }, set: { newValue in
                                viewModel.sleepInterval.end = newValue
                            }), in: viewModel.sleepInterval.begin...viewModel.smallestBeginDate)
                            .labelsHidden()
                            .datePickerStyle(.compact)
                            
                        }
                        .listRowBackground(Color.darkPurpleBackground)
                        .padding()
                        .background(Color.lightPurpleBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 15 ))
                    }.listSectionSeparatorTint(.darkPurpleBackground)
                        .listRowSeparatorTint(.darkPurpleBackground)
                .listRowInsets(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10)) // Apply insets to round the corners
                    .listRowBackground(Color.darkPurpleBackground)
                   
                } .listStyle(PlainListStyle())
                    .frame(maxHeight: .infinity)
                
                
                HStack{
                    Spacer()
                    Button(action: {
                        viewModel.sleepIntervalsTemp.append(viewModel.sleepInterval)
                        viewModel.sleepIntervalsTemp.sort { $0.begin < $1.begin }
                        viewModel.checkOverlappingIntervals()
                        viewModel.isAddVisible.toggle()
                    }) {
                        Text("Save")
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 20)
                            .background(Color.lightButton)
                            .cornerRadius(15)
                    }
                    Spacer()
                    Button(action: {
                        viewModel.isAddVisible.toggle()
                    }) {
                        Text("Cancel")
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 20)
                            .background(Color.lightButton)
                            .cornerRadius(15)
                    }
                    Spacer()
                }
                .padding(.vertical, 30.0)
            }.opacity(viewModel.isAddVisible ? 1.0 : 0.0)
            .frame(maxWidth: UIScreen.main.bounds.width , maxHeight: UIScreen.main.bounds.height)
        }.listRowBackground(Color.darkPurpleBackground)
        
        
        }
            
        
}
   



struct SleepIntervalTemp {
    var id: UUID
    var begin: Date
    var end: Date
}


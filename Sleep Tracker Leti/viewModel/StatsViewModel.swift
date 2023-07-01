
import CoreData
import SwiftUI

class StatsViewModel: ObservableObject {
    
    @Published var sleepDurations: [String: Double] = [:]
    @Published var isEditVisible = false
    @Published var showingExporter = false
    @Published var sleepArray: [Sleep] = []
    @Published var chartData: [ String : [SavingsDataPoint]] = [ "Weekly" : [],
                                                                 "Daily": [] ]
    
    private let viewContext = PersistenceController.shared.viewContext
    
    
    func fetchSleepData () {
        let request = NSFetchRequest<Sleep>(entityName: "Sleep")
        do {
            sleepArray = try viewContext.fetch(request)
        } catch {
            print("DEBUG: Some error occured while fetching")
        }
        
    }
    func fetchSleepsLastWeek()  {
        // Получить дату 7 дней назад
        sleepDurations = ["Mon": 0 , "Tue" : 0, "Wed" : 0, "Thu" : 0, "Fri" : 0, "Sat" : 0, "Sun" : 0]
        let calendar = Calendar.current
        let today = Date()
        let currentDayOfWeek = calendar.component(.weekday, from: today)
        let lastWeek = calendar.date(byAdding: .day, value: -7, to: today)!
        // Запрос Sleep объектов с датой >= lastWeek
        let request = Sleep.fetchRequest()
        do {
            request.predicate = NSPredicate(format: "ANY sleepToSleepIntervals.begin >= %@", lastWeek as NSDate)
            let sleeps = try self.viewContext.fetch(request)
            
            // Создаем словарь с общей продолжительностью для каждого дня
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "E"
            for sleep in sleeps {
                if let sleepIntervals = sleep.sleepToSleepIntervals?.allObjects as? [SleepInterval] {
                    for sleepInterval in sleepIntervals {
                        if let begin = sleepInterval.begin, let end = sleepInterval.end {
                            let duration = end.timeIntervalSince(begin) / 3600
                            let dateString = dateFormatter.string(from: begin)
                            if let currentDuration = sleepDurations[dateString] {
                                sleepDurations[dateString] = currentDuration + duration
                            }
                        }
                    }
                }
            }
            
            let sortedDurationsByDay = sleepDurations.sorted { (entry1, entry2) -> Bool in
                let dayOfWeek1 = calendar.shortWeekdaySymbols.firstIndex(of: entry1.key) ?? 0
                let dayOfWeek2 = calendar.shortWeekdaySymbols.firstIndex(of: entry2.key) ?? 0
                let distance1 = (dayOfWeek1 + 7 - currentDayOfWeek) % 7
                let distance2 = (dayOfWeek2 + 7 - currentDayOfWeek) % 7
                return distance1 < distance2
            }
            
            self.chartData["Weekly"] = sortedDurationsByDay.map { SavingsDataPoint(month: $0.key, value: $0.value) }
            
        } catch let error {
            print("Error fetching sleeps: \(error.localizedDescription)")
        }
    }
    
    
    
    func createExportString() -> String {
        // Заголовок для CSV
        var export: String = "Sleep Interval begin, Sleep Interval End, Duration\n"
        // Запрос всех Sleep объектов
        let request = Sleep.fetchRequest()
        do {
            let sleeps = try self.viewContext.fetch(request)
            // Проверяем, не пуст ли массив sleeps
            if sleeps.isEmpty   {
                print("No Sleep data available for export.")
                return export
            } else { for sleep in sleeps{
                print("\(sleep.edited)")
            }}
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            
            // Для каждого Sleep объекта, выбираем все его SleepInterval
            for sleep in sleeps {
                let sleepIntervals = sleep.sleepArray
                if sleepIntervals.isEmpty {
                    print("No SleepInterval data available for current Sleep object.")
                    return export
                }
                for sleepInterval in sleepIntervals {
                    guard let begin = sleepInterval.begin, let end = sleepInterval.end else {
                        print("Invalid SleepInterval data (nil begin or end).")
                        continue
                    }
                    
                    let beginString = dateFormatter.string(from: begin)
                    let endString = dateFormatter.string(from: end)
                    let duration = end.timeIntervalSince(begin)
                    export += "\(beginString),\(endString),\(duration)\n"
                }
            }
            
        } catch let error {
            print("Error fetching sleeps: \(error.localizedDescription)")
        }
        
        return export
    }
    
    func fetchSleepsForDayIntervalsLast24Hours()  {
        let timeIntervals = ["0-4", "4-8", "8-12", "12-16", "16-20", "20-24"]
        var timeDurations: [String: Double] = [:]
        
        for interval in timeIntervals {
            timeDurations[interval] = 0
        }
        
        
        let request = SleepInterval.fetchRequest()
        let twentyFourHoursAgo = Calendar.current.date(byAdding: .hour, value: -24, to: Date())!
        request.predicate = NSPredicate(format: "end >= %@", twentyFourHoursAgo as NSDate)
        
        do {
            let sleepIntervals = try self.viewContext.fetch(request)
            
            
            for sleepInterval in sleepIntervals {
                if let begin = sleepInterval.begin, let end = sleepInterval.end {
                    print("\(begin )+\(end)")
                    let startOfDay = Calendar.current.startOfDay(for: begin)
                    print("startOfDay \(startOfDay)")
                    let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
                    print("endOfDay \(endOfDay)")
                    var currentInterval = Calendar.current.component(.hour, from: begin) / 4
                    print("currentInterval \(currentInterval)")
                    var currentTime = begin
                    print("currentTime \(currentTime)")
                    while currentTime < end {
                        let currentHour = ((currentInterval + 1) * 4) % 24
                        print("currentHour \(currentHour)")
                        var nextTime: Date
                        if currentHour == 0 {
                            nextTime = min(end, endOfDay)
                        } else {
                            let nextIntervalStart = Calendar.current.date(bySettingHour: currentHour, minute: 0, second: 0, of: currentTime)!
                            print("nextIntervalStart \(nextIntervalStart)")
                            nextTime = min(nextIntervalStart, end)
                            print("next time\(nextTime)")
                        }
                        
                        let duration = nextTime.timeIntervalSince(currentTime)/3600
                        print("duration \(duration)")
                        let intervalString = timeIntervals[currentInterval % timeIntervals.count]
                        timeDurations[intervalString, default: 0] += duration
                        
                        currentInterval = (currentInterval + 1) % timeIntervals.count
                        currentTime = nextTime
                    }
                }
                
            }
            let currentHour = Calendar.current.component(.hour, from: Date())
            let currentIntervalIndex = currentHour / 4
            
            let sortedTimeIntervals = timeIntervals.sorted { (interval1, interval2) -> Bool in
                let index1 = timeIntervals.firstIndex(of: interval1)!
                let index2 = timeIntervals.firstIndex(of: interval2)!
                let distance1 = (index1 + timeIntervals.count - currentIntervalIndex) % timeIntervals.count
                let distance2 = (index2 + timeIntervals.count - currentIntervalIndex) % timeIntervals.count
                return distance1 < distance2
            }
            
            self.chartData["Daily"] = sortedTimeIntervals.map { interval in
                SavingsDataPoint(month: interval, value: timeDurations[interval] ?? 0)
            }
            
            self.chartData["Daily"] = sortedTimeIntervals.map { interval in
                SavingsDataPoint(month: interval, value: timeDurations[interval] ?? 0)
            }
            
            
            
        } catch let error {
            print("Error fetching sleeps: \(error.localizedDescription)")
        }
    }
    
    
    
    
    
    
    
    func toggleExporter() {
        showingExporter.toggle()
    }
    
    // Добавьте любые другие функции, которые вы хотите вынести в ViewModel
}


import NotificationCenter
import Combine
import SwiftUI
import CoreData
import CoreLocation

class SleepAppViewModel: ObservableObject {
    
    @Published var showingHelloView = true
    
    private var cancellables = Set<AnyCancellable>()
    @Published  var lastScreenLockedTime: Date? = Date()
    @Published  var lastScreenUnlockedTime: Date? = Date()
    @Published var isScreenLocked: Bool = false
    @Published var isSleepStatus: Bool = false
    let viewContext = PersistenceController.shared.viewContext
    let calendar = Calendar.current
    let currentDate = Date()
    @Published var twoHoursAgo = Date()
    @Published var locationsArray: [Location] = []
    @State var badgeManager = AppAlertBadgeManager(application: UIApplication.shared)
    @Published var notEditedSleeps: [Sleep] = []
    
    @MainActor
    func subscribeToScreenLockNotifications() {
        NotificationCenter.default.publisher(for: UIApplication.protectedDataWillBecomeUnavailableNotification)
            .sink { _ in
                self.isScreenLocked = true
                self.lastScreenLockedTime = Date()
                print("Screen locked at \(self.lastScreenLockedTime)")
                //    self.resetdata()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.protectedDataDidBecomeAvailableNotification)
            .sink { [self] _ in
                self.isScreenLocked = false
                self.lastScreenUnlockedTime = Date()
                let timeDifference = Calendar.current.dateComponents([.minute], from: lastScreenLockedTime!, to: lastScreenUnlockedTime!).minute ?? 0
                print("Screen unlocked at \(self.lastScreenUnlockedTime)")
                print("\(timeDifference)")
                calculateSleepIntervals(startDate: lastScreenLockedTime!, endDate: lastScreenUnlockedTime!)
                setBages()
                notEditedSleeps = fetchSleepsWithEditStatusFalse()
            }
            .store(in: &cancellables)
        
    }
 
    func unsubscribeFromScreenLockNotifications() {
        cancellables.forEach { $0.cancel() }
    }
    
    @MainActor
    func setBages () {
        let sleeps = fetchSleepsWithEditStatusFalse()
        print("\(sleeps.count)")
        badgeManager.setAlertBadge(number: sleeps.count)
    }
    func calculateSleepIntervals(startDate: Date, endDate: Date) {
        do {
            if endDate.timeIntervalSince(startDate) > 1800 {
                let locations = try fetchLocations(in: viewContext, from: startDate, to: endDate)
                if locations.isEmpty == false {
                    let tempLocationIntervals = processLocations(locations: locations)
                    let tempSoundIntervals = try evaluateNoise(for: tempLocationIntervals, in: viewContext)
                    if tempSoundIntervals.isEmpty == false {
                        let sleep = Sleep(context: viewContext)
                        sleep.id = UUID()
                        sleep.edited = false
                        for item in tempSoundIntervals {
                            let sleepInterval = SleepInterval(context: viewContext)
                            sleepInterval.id = UUID()
                            sleepInterval.begin = item.begin
                            sleepInterval.end = item.end
                            sleepInterval.sleepIntervalToSleep = sleep
                            sleep.addToSleepToSleepIntervals(sleepInterval)
                        }
                        viewContext.saveContext()
                    }}}
        } catch {
            print("An error occurred while calculate slee intervals: \(error)")
        }
    }
    
    
    func fetchLocationsData(from startDate: Date, to  endDate: Date) {
        let request = NSFetchRequest<Location>(entityName: "Location")
        let predicate = NSPredicate(format: "time >= %@ AND time <= %@", startDate as NSDate, endDate as NSDate)
        request.predicate = predicate
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Location.time, ascending: true)]
        
        do {
            locationsArray = try viewContext.fetch(request)
        } catch {
            print("DEBUG: Some error occurred while fetching")
        }
    }
  
    func fetchSleepsWithEditStatusFalse() -> [Sleep] {
        let request: NSFetchRequest<Sleep> = Sleep.fetchRequest()
        request.predicate = NSPredicate(format: "edited == %@", NSNumber(value: false))
        
        do {
            let sleeps = try viewContext.fetch(request)
            let sortedSleeps = sleeps.sorted { (sleep1, sleep2) -> Bool in
                if let sleepIntervals1 = sleep1.sleepToSleepIntervals as? Set<SleepInterval>,
                   let sleepIntervals2 = sleep2.sleepToSleepIntervals as? Set<SleepInterval>,
                   let firstInterval1 = sleepIntervals1.first,
                   let firstInterval2 = sleepIntervals2.first {
                    return (firstInterval1.begin ?? Date()) > (firstInterval2.begin ?? Date())
                }
                return false
            }
            return sortedSleeps
        } catch let error {
            print("Error fetching sleeps: \(error.localizedDescription)")
            return []
        }
    }
    
    
    
    // Функция для получения местоположений за определенный промежуток времени
    func fetchLocations(in context: NSManagedObjectContext, from startDate: Date, to endDate: Date) throws -> [Location] {
        let fetchRequest: NSFetchRequest<Location> = Location.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "(time >= %@) AND (time <= %@)", startDate as NSDate, endDate as NSDate)
        return try context.fetch(fetchRequest)
    }
    
    func fetchSounds(in context: NSManagedObjectContext, for interval: TempSleepInterval) throws -> [Sound] {
        let fetchRequest: NSFetchRequest<Sound> = Sound.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "(time >= %@) AND (time <= %@)", interval.begin! as NSDate, interval.end! as NSDate)
        
        let sortDescriptor = NSSortDescriptor(key: "time", ascending: true) // Сортировка по возрастанию даты
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        return try context.fetch(fetchRequest)
    }
    
    // Расчет расстояния между двумя местоположениями
    func calculateDistance( startLocation: Location, endLocationLatitude: Double, endLocationLongitude: Double) -> Double {
        // Создание объектов CLLocation для каждого местоположения
        let coordinateStart = CLLocation(latitude: startLocation.latitude, longitude: startLocation.longitude)
        let coordinateEnd = CLLocation(latitude: endLocationLatitude, longitude: endLocationLongitude)
        // Расчет и возврат расстояния между местоположениями
        return coordinateStart.distance(from: coordinateEnd)
    }
    // Обрабатывает список местоположений и возвращает список интервалов сна
    func processLocations(locations: [Location]) -> [TempSleepInterval] {
        var intervals: [TempSleepInterval]
        var batchSize = 30 // Размер пакета локаций для обработки за один проход
        var startIndex = 0 // Начальный индекс для текущей партии
        var endIndex = startIndex + batchSize // Конечный индекс для текущей партии
        
        while batchSize > 5 {
            while endIndex + batchSize/2 <= locations.count {
                let batch = Array(locations[startIndex..<endIndex]) // Получение текущей партии
                let averageLatitude = batch.reduce(0.0, { $0 + $1.latitude }) / Double(batchSize) // Расчет средней широты
                let averageLongitude = batch.reduce(0.0, { $0 + $1.longitude }) / Double(batchSize) // Расчет средней долготы
                
                for location in batch { // Обход всех местоположений в пакете
                    
                    let distance = calculateDistance(startLocation: location, endLocationLatitude: averageLatitude, endLocationLongitude: averageLongitude) // Расчет расстояния
                    
                    if distance < 10.0 {
                        // Если расстояние меньше 5 метров, увеличиваем счет местоположения
                        location.score += 1
                        
                    }
                }
                // Сдвиг индексов для следующего прохода
                startIndex += batchSize/2
                endIndex += batchSize/2
            }
            
            batchSize -= 10 // Уменьшение размера партии
            startIndex = 0 // Начальный индекс для текущей партии
            endIndex = startIndex + batchSize
        }
        // Расчет интервалов сна на основе обработанных местоположений
        intervals = calculateTimeInterval(locationScores: locations)
        // Возврат списка интервалов сна
        return intervals
    }
    
    
    // Расчет временных интервалов сна на основе оценки местоположений
    func calculateTimeInterval(locationScores: [Location]) -> [TempSleepInterval] {
        var intervals: [TempSleepInterval] = [] // Инициализация массива интервалов сна
        var sleepInterval = TempSleepInterval(begin: nil, end: nil) // Временный интервал сна
        var consecutiveCount = 0 // Счетчик последовательных местоположений с высоким рейтингом
        
        // Проходим по всем местоположениям
        for (index, location) in locationScores.enumerated() {
            if location.score >= 3 { // Если рейтинг местоположения выше или равен 4
                consecutiveCount += 1 // Увеличиваем счетчик
            } else {
                if consecutiveCount >= 15 { // Если накоплено более 15 последовательных местоположений с высоким рейтингом
                    let firstIndex = index - consecutiveCount + 1 // Индекс начала интервала
                    let lastIndex = index // Индекс конца интервала
                    
                    let start = locationScores[firstIndex].time // Время начала интервала
                    let end = locationScores[lastIndex].time // Время конца интервала
                    
                    sleepInterval.begin = start // Устанавливаем время начала интервала сна
                    sleepInterval.end = end // Устанавливаем время конца интервала сна
                    intervals.append(sleepInterval) // Добавляем интервал сна в массив
                }
                consecutiveCount = 0 // Обнуляем счетчик последовательных местоположений с высоким рейтингом
            }
        }
        return intervals // Возвращаем полученные интервалы сна
    }
    
    
    func evaluateNoise(for sleepIntervals: [TempSleepInterval], in context: NSManagedObjectContext) throws -> [TempSleepInterval] {
        var actualSleepIntervals: [TempSleepInterval] = []
        let batchSize = 300 // Размер партии локаций для обработки за один проход
        var startIndex = 0 // Начальный индекс для текущей партии
        var noiseCount = 0
        var endIndex = startIndex + batchSize // Конечный индекс для текущей партии
        var notSleepIntervals: [TempSleepInterval] = []
        var tempSleepInterval = TempSleepInterval(begin: nil, end: nil)
        var tempsleepsIntervals: [TempSleepInterval] = []
        
        // Получаем звуки для указанного интервала сна
        for sleepInterval in sleepIntervals {
            let sounds = try fetchSounds(in: context, for: sleepInterval)
            
            while endIndex + batchSize <= sounds.count {
                // Вычисляем средний уровень шума
                let batch = Array(sounds[startIndex..<endIndex]) // Получение текущей партии
                let averageNoise = 1.2 * batch.reduce(0.0, { $0 + Double($1.noise) }) / Double(batch.count)
       
                // Проверяем каждый звук на соответствие определенным условиям шума
                for sound in batch {
                    var score = 0
                    
                    if sound.noise > 35 {
                        score += 1
                    }
                    
                    if sound.noise > 55 {
                        score += 1
                    }
                    
                    if sound.noise >  Int(round(averageNoise))  {
                        score += 1
                    }
                    
                    if score >= 2 {
                        noiseCount  += 1
                    }
                    //  print("sound at \(sound.time) = \(score)")
                }
                
                if noiseCount > 20 {
                    tempSleepInterval = TempSleepInterval(begin: batch.first?.time, end: batch.last?.time)
                    if tempsleepsIntervals.isEmpty == true || tempSleepInterval.end!.timeIntervalSince(tempsleepsIntervals.last!.end!) < 300 {
                        tempsleepsIntervals.append(tempSleepInterval)
                    } else {
                        tempSleepInterval.begin = tempsleepsIntervals.first?.begin
                        tempSleepInterval.end = tempsleepsIntervals.last?.end
                        notSleepIntervals.append(tempSleepInterval)
                        tempsleepsIntervals.removeAll()
                    }
                }
                noiseCount = 0
                startIndex = endIndex // Начальный индекс для текущей партии
                endIndex = startIndex + batchSize
                
            }
            tempSleepInterval.begin = sleepInterval.begin
            tempSleepInterval.end = sleepInterval.end
            // Обрабатываем шумовые интервалы и находим фактические интервалы сна
            for notSleepInterval in notSleepIntervals {
                if tempSleepInterval.begin! < notSleepInterval.begin! && tempSleepInterval.end! > notSleepInterval.end! {
                    // шумовой интервал полностью находится внутри интервала сна
                    actualSleepIntervals.append(TempSleepInterval(begin: tempSleepInterval.begin, end: notSleepInterval.begin))
                    tempSleepInterval.begin = notSleepInterval.end
                }
            }
            actualSleepIntervals.append(tempSleepInterval)
            
        }
        // Отфильтровываем интервалы, продолжительность которых больше 10 минут
        actualSleepIntervals = actualSleepIntervals.filter { $0.end!.timeIntervalSince($0.begin!) > 600 }
        
        return actualSleepIntervals
    }
    
}

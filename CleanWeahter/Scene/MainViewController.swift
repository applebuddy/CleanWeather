//
//  MainViewController.swift
//  CleanWeahter
//
//  Created by Seokho on 2020/10/26.
//  Copyright (c) 2020 ___ORGANIZATIONNAME___. All rights reserved.
//
//  This file was generated by the Clean Swift Xcode Templates so
//  you can apply clean architecture to your iOS and Mac projects,
//  see http://clean-swift.com
//
import CoreLocation
import UIKit

protocol MainDisplayLogic: class {
	func showErrorAlert(errorViewModel: Main.MainError.ViewModel)
	func reloadData(viewModel: Main.FetchWeather.ViewModel)
}

class MainViewController: BaseViewController, MainDisplayLogic {
	
	var interactor: MainBusinessLogic?
	var router: (NSObjectProtocol & MainRoutingLogic & MainDataPassing)?
	var weather: Weather?
	var cache = Cache()
	
	// MARK: Object lifecycle
	
	lazy var tableView: UITableView = {
		let tableView = UITableView()
		tableView.translatesAutoresizingMaskIntoConstraints = false
		tableView.tableFooterView = UIView()
		tableView.register(TodayCell.self, forCellReuseIdentifier: "\(TodayCell.self)")
		tableView.register(ForecastCell.self, forCellReuseIdentifier:  "\(ForecastCell.self)")
		tableView.dataSource = self
		tableView.delegate = self
		tableView.allowsSelection = false
		return tableView
	}()
	
	override init() {
		super.init()
		setup()
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		setup()
	}
	
	override func configureUI() {
		self.view.addSubview(tableView)
	}
	
	override func setupConstraints() {
		NSLayoutConstraint.activate([
			tableView.widthAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.widthAnchor),
			tableView.heightAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.heightAnchor),
			tableView.centerYAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerYAnchor),
			tableView.centerXAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerXAnchor)
		])
	}
	
	// MARK: Setup
	
	private func setup() {
		let viewController = self
		
		let repository = MainRepository()
		let worker = MainWorker(mainRepository: repository)
		let interactor = MainInteractor(worker: worker)
		let presenter = MainPresenter()
		let router = MainRouter()
		viewController.interactor = interactor
		viewController.router = router
		interactor.presenter = presenter
		presenter.viewController = viewController
		router.viewController = viewController
		router.dataStore = interactor
	}
	
	// MARK: View lifecycle
	override func viewDidLoad() {
		super.viewDidLoad()
		requestFetchData()
		
	}
	
	func requestFetchData() {
		
		let request = Main.FetchWeather.Request(unit: "c")
		self.interactor?.fetchData(request: request)
		
	}
	
	func showErrorAlert(errorViewModel: Main.MainError.ViewModel) {
		DispatchQueue.main.async {
			let alert = UIAlertController(title: "Error", message: errorViewModel.localError, preferredStyle: .alert)
			let okAction = UIAlertAction(title: "확인", style: . default)
			alert.addAction(okAction)
			
			self.present(alert, animated: true)
		}
	}
	
	func reloadData(viewModel: Main.FetchWeather.ViewModel) {
		self.weather = viewModel.weather
		
		DispatchQueue.main.async {
			self.tableView.reloadData()
		}
	}
	
}
extension MainViewController: UITableViewDataSource {
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		
		if let weather = self.weather {
			return weather.forecasts.count + 1
		} else {
			return 0
		}
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		
		guard let weather = self.weather  else {
			return UITableViewCell()
		}
		
		let celltype = CellType(rawValue: indexPath.row)!
		if celltype == .today,
		   let cell = tableView.dequeueReusableCell(withIdentifier: "\(TodayCell.self)", for: indexPath) as? TodayCell {
			cell.configure(cache: self.cache)
			let todayDTO = TodayDTO(cityName: weather.location.city, regionName: weather.location.region, weather: weather.currentObservation.condition.text, temp: "\(weather.currentObservation.condition.temperature)", weatherCode: weather.currentObservation.condition.code)
			cell.bindUI(todayDTO: todayDTO)
			
			return cell
		} else if celltype == .forcast,
				  let cell = tableView.dequeueReusableCell(withIdentifier: "\(ForecastCell.self)", for: indexPath) as? ForecastCell {
			cell.configure(cache: self.cache)
			
			let forcast = weather.forecasts[indexPath.row - 1]
			let dto = ForecastDTO(weekend: forcast.day, date: forcast.date, minTemp: forcast.low, maxTemp: forcast.high, weatherCode: forcast.code)
			cell.bindUI(dto: dto)
		}
		
		return UITableViewCell()
		
	}
	
	
}
extension MainViewController: UITableViewDelegate {
	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		
		let cellType = CellType(rawValue: indexPath.row)!
		if cellType == .today {
			return 200
		} else {
			return 90
		}
	}
}

enum CellType: Int {
	case today
	case forcast
	
	init?(rawValue: Int) {
		if rawValue == 0 {
			self = .today
		} else {
			self = .forcast
		}
	}
}

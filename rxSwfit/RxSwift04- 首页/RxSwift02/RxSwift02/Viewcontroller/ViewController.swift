//
//  ViewController.swift
//  RxSwift02
//
//  Created by CQCA202121101_2 on 2025/11/5.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit

class ViewController: UIViewController {
    private let viewModel = HomeViewModel()
    private let disposeBag = DisposeBag()
    private let refreshControl = UIRefreshControl()
    private let loadingView = UIActivityIndicatorView(style: .large)
    private let favoriteTappedRelay = PublishRelay<Int>()
    private let profiletTappedReplay = PublishRelay<Void>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupBindings()
    }
    
    private func setupUI() {
        title = "商品列表"
        view.backgroundColor = .systemBackground
        setupNavigatioinBar()
        setupTableView()
        seupLoadingView()
    }
    
    private func setupNavigatioinBar() {
        navigationController?.navigationBar.prefersLargeTitles = false
    }
    
    private func setupTableView() {
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        tableView.refreshControl = refreshControl
        setupTableHeaderView()
    }
    
    private func setupTableHeaderView() {
        let containerView = UIView()
        containerView.addSubview(headView)
        headView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        tableView.tableHeaderView = containerView
        containerView.snp.makeConstraints { make in
            make.width.equalTo(tableView)
            make.height.equalTo(120)
        }
        tableView.tableHeaderView = containerView
    }
    
    func seupLoadingView() {
        view.addSubview(loadingView)
        loadingView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    private func setupBindings() {
        headView.profileTapped
            .bind(to: profiletTappedReplay)
            .disposed(by: disposeBag)
        
        let input = HomeViewModel.Input(
            viewDidLoad: Observable.just(()),
            refresh: refreshControl.rx.controlEvent(.valueChanged).asObservable(),
            productSeleted: tableView.rx.itemSelected.asObservable(),
            favoriteTapped: favoriteTappedRelay.asObservable(),
            profileTapped: profiletTappedReplay.asObservable())
        
        let output = viewModel.transForm(input: input)
        
        bindUserInfo(output: output)
        bindProducts(output: output)
        bindLoadingState(output: output)
        bindErrors(outpu: output)
        bindNavigation(output: output)
    }
    
    private func bindUserInfo(output: HomeViewModel.Output) {
        output.user.drive { [weak self] user in
            if let user = user {
                self?.headView.configure(with: user)
            }
        }.disposed(by: disposeBag)
    }
    
    private func bindProducts(output: HomeViewModel.Output) {
        output.products
            .drive(tableView.rx.items(cellIdentifier: "ProductCellID", cellType: ProductCell.self)) { [weak self] index, product, cell in
                cell.configure(with: product)
                cell.favoriteTapped = {
                    self?.favoriteTappedRelay.accept(product.id)
                }
            }.disposed(by: disposeBag)
    }
    
    private func bindLoadingState(output: HomeViewModel.Output) {
        output.isLoading
             .drive(onNext: { [weak self] isLoading in
                 isLoading ? self?.loadingView.startAnimating() : self?.loadingView.stopAnimating()
                 if !isLoading {
                     self?.refreshControl.endRefreshing()
                 }
             })
             .disposed(by: disposeBag)
    }
    
    private func bindErrors(outpu: HomeViewModel.Output) {
        outpu.error.drive ( onNext: {  [weak self] errorMessage   in
            if !errorMessage.isEmpty {
                
            }
        })
    }
    
    func bindNavigation(output: HomeViewModel.Output) {
        output.selectedProduct
            .drive ( onNext: { [weak self] product in
                self?.navigateToProductDetail(product: product)
            })
            .disposed(by: disposeBag)
        
        output.navigateToProfile
            .drive( onNext: { [weak self] in
                self?.navigateToProfile()
            })
            .disposed(by: disposeBag)

    }
    
    func navigateToProductDetail(product: Product) {
        let detailVC = ProductDetailViewController(product: product)
        navigationController?.pushViewController(detailVC, animated: true)
    }

    
    func navigateToProfile() {
        let profileVC = ProfileViewController()
        navigationController?.pushViewController(profileVC, animated: true)
    }
    
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "错误", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
        
    }
    
    
    
    private lazy var headView: UserInfoHeaderView = {
        let view = UserInfoHeaderView()
        return view
    }()
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(ProductCell.self, forCellReuseIdentifier: "ProductCellID")
        tableView.rowHeight = 104
        tableView.separatorStyle = .none
        return tableView
    }()

}


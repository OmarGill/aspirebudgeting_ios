//
//  DashboardView.swift
//  Aspire Budgeting
//

import SwiftUI

struct DashboardView: View {

  let viewModel: DashboardViewModel
  @State private var searchText = ""

  var body: some View {
    VStack {
      if viewModel.error == nil {
        if viewModel.dashboard?.groups != nil {
          SearchBar(text: $searchText)
            .ignoreKeyboard()
          if searchText.isEmpty {
            CardListView(cardViewItems: viewModel.cardViewItems)
              .padding(.vertical, 10)
          } else {
            CategoryListView(categories: viewModel.filteredCategories(filter: searchText),
                             tintColor: .greenFondEndColor)
          }

        } else {
          GeometryReader { geo in
            LoadingView(height: geo.frame(in: .local).size.height)
          }
        }
      } else {
        ZStack {
          Rectangle().foregroundColor(Colors.aspireGray).edgesIgnoringSafeArea(.all)
          ErrorBannerView(error: viewModel.error!)
        }
      }
    }
    .background(Color.primaryBackgroundColor)
      .onAppear {
        self.viewModel.refresh()
      }
  }
}

extension View {
  @ViewBuilder
  func ignoreKeyboard() -> some View {
    if #available(iOS 14.0, *) {
      ignoresSafeArea(.keyboard, edges: .all)
    } else {
      self
    }
  }
}

// struct DashboardView_Previews: PreviewProvider {
//    static var previews: some View {
//        DashboardView()
//    }
// }

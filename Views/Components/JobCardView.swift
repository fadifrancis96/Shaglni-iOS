//
//  JobCardView.swift
//  Shaglni
//
//  The canonical job row used on dashboards and lists: category icon,
//  title + meta, status pill, budget and posted time.
//

import SwiftUI

struct JobCardView: View {
    let job: Job
    @EnvironmentObject var localization: LocalizationManager

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.m) {
            HStack(alignment: .top, spacing: DS.Space.m) {
                DSCategoryIcon(category: job.category ?? .other)

                VStack(alignment: .leading, spacing: 4) {
                    Text(job.title)
                        .font(.dsHeadline)
                        .foregroundStyle(Color.ink)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    HStack(spacing: 4) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 11))
                        Text(job.location)
                            .lineLimit(1)
                    }
                    .font(.dsCaption)
                    .foregroundStyle(Color.inkMuted)
                }

                Spacer(minLength: DS.Space.s)

                DSStatusPill(status: job.status)
            }

            if !job.description.isEmpty {
                Text(job.description)
                    .font(.dsSub)
                    .foregroundStyle(Color.inkMuted)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }

            Divider().overlay(Color.divider)

            HStack {
                if let budget = job.budget {
                    DSPriceText(amount: budget)
                }
                if let category = job.category {
                    DSTag(title: category.localized)
                }

                Spacer()

                Text(job.datePosted, style: .relative)
                    .font(.dsCaption)
                    .foregroundStyle(Color.inkFaint)
            }
        }
        .dsCard()
    }
}

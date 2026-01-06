//
//  ArticlesView.swift
//  Run
//
//  Created by Artem Menshikov on 04.01.2026.
//

import SwiftUI

struct ArticlesView: View {
    let articles: [Article] = [
        Article(
            title: "Runner Injuries and Prevention",
            content: """
            Understanding common injuries helps prevent and properly treat them.
            
            **Main Runner Injuries:**
            
            1. **Runner's Knee (IT Band Syndrome)**
            • Symptoms: pain on the outer side of the knee
            • Causes: weak gluteal muscles, incorrect technique
            • Prevention: strengthen glutes, stretch IT band
            
            2. **Plantar Fasciitis**
            • Symptoms: heel pain, especially in the morning
            • Causes: overuse, inappropriate footwear
            • Prevention: stretch calves, proper footwear selection, foot massage
            
            3. **Shin Splints (Tibial Stress Syndrome)**
            • Symptoms: pain along the inner side of the shin
            • Causes: sudden increase in load, weak muscles
            • Prevention: gradual increase in load, strengthen shins
            
            4. **Achilles Tendinitis**
            • Symptoms: pain in the back of the heel/calf
            • Causes: overuse, insufficient warm-up
            • Prevention: stretch calves, gradual increase in speed
            
            5. **Stress Fracture**
            • Symptoms: localized pain that worsens when running
            • Causes: overtraining, insufficient recovery
            • Prevention: adequate rest, proper nutrition
            
            6. **Hamstring Strain**
            • Symptoms: sharp pain, muscle spasms
            • Causes: insufficient warm-up, fatigue
            • Prevention: quality warm-up, strengthen muscles
            
            7. **Patellofemoral Pain Syndrome**
            • Symptoms: pain around or behind the kneecap
            • Causes: weak thigh muscles, incorrect technique
            • Prevention: strengthen quadriceps, stretching
            
            8. **Iliotibial Band Syndrome**
            • Symptoms: burning or pain on the side of the knee
            • Causes: weak glutes, flat feet
            • Prevention: strengthen gluteal muscles, orthopedic insoles
            
            **General Prevention Principles:**
            
            • Gradual increase in load (10% rule)
            • Quality warm-up and cool-down
            • Strengthen stabilizing muscles
            • Adequate rest and recovery
            • Proper running technique
            • Appropriate footwear
            • Listen to your body - don't ignore pain
            
            **Signs of Overtraining:**
            • Constant fatigue
            • Muscle and joint pain
            • Decreased motivation
            • Sleep disturbance
            • Decreased performance
            
            **If an Injury Occurs:**
            • Rest and reduce load
            • Ice for the first 48 hours (15-20 minutes, 3-4 times a day)
            • See a specialist for severe pain
            • Gradual return to running after recovery
            
            For serious injuries, be sure to consult a doctor!
            """,
            icon: "cross.case"
        ),
        Article(
            title: "Proper Running Technique",
            content: """
            Proper running technique is the foundation of effective training and injury prevention.
            
            Key points:
            • Keep your back straight but not tense
            • Land on the middle part of your foot, not your heel
            • Keep your arms bent at a 90-degree angle
            • Look ahead, not down
            • Breathe rhythmically, synchronizing with your steps
            • Take short, quick steps
            """,
            icon: "figure.run"
        ),
        Article(
            title: "How to Start Running",
            content: """
            It's important for beginner runners to gradually increase their load.
            
            Beginner program:
            • Weeks 1-2: 20 minutes walking, 1 minute running, repeat 5 times
            • Weeks 3-4: 2 minutes running, 1 minute walking, repeat 6 times
            • Weeks 5-6: 3 minutes running, 1 minute walking, repeat 6 times
            • Week 7+: gradually increase running time
            
            Don't forget:
            • Always warm up before running
            • Drink enough water
            • Give your body time to recover
            """,
            icon: "figure.walk"
        ),
        Article(
            title: "Warm-up and Cool-down",
            content: """
            Proper warm-up and cool-down are the keys to a successful workout.
            
            Warm-up (5-10 minutes):
            • Light walking or jogging
            • Dynamic stretching (leg swings, circular movements)
            • Prepare joints for load
            
            Cool-down (5-10 minutes):
            • Gradual slowdown of pace
            • Static muscle stretching
            • Heart rate recovery
            • Fluid replenishment
            """,
            icon: "figure.flexibility"
        ),
        Article(
            title: "Nutrition for Runners",
            content: """
            Proper nutrition is important for effective training.
            
            Before running (1-2 hours before):
            • Light snack with carbohydrates (banana, oatmeal)
            • Avoid heavy and fatty foods
            
            After running (within 30 minutes):
            • Protein for muscle recovery
            • Carbohydrates to replenish energy
            • Water or sports drink
            
            General recommendations:
            • Balanced diet
            • Sufficient water intake
            • Vitamins and minerals
            """,
            icon: "fork.knife"
        ),
        Article(
            title: "Running in Different Seasons",
            content: """
            Adaptation to weather conditions.
            
            Summer:
            • Run in the morning or evening
            • Drink more water
            • Wear light clothing
            • Use sunscreen
            
            Winter:
            • Layered clothing
            • Wind protection
            • Warm up at home before going out
            • Caution on slippery surfaces
            
            Spring/Fall:
            • Ideal time for running
            • Comfortable temperature
            • Pleasant weather for long runs
            """,
            icon: "cloud.sun"
        )
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Decorative neomorphic circles with different radii
                NeomorphicCircle(radius: 120, offset: CGSize(width: -100, height: -200))
                    .allowsHitTesting(false)
                NeomorphicCircle(radius: 150, offset: CGSize(width: 150, height: 300))
                    .allowsHitTesting(false)
                NeomorphicCircle(radius: 100, offset: CGSize(width: -120, height: 400))
                    .allowsHitTesting(false)
                NeomorphicCircle(radius: 80, offset: CGSize(width: 200, height: 100))
                    .allowsHitTesting(false)
                NeomorphicCircle(radius: 110, offset: CGSize(width: -150, height: 600))
                    .allowsHitTesting(false)
                
                List(articles) { article in
                NavigationLink(destination: ArticleDetailView(article: article)) {
                    ArticleRowView(article: article)
                }
                .listRowBackground(Color.white.opacity(0.5))
            }
            .listStyle(.plain)
            .listRowSeparator(.hidden)
            .background(Color.clear)
            .onAppear {
                // Make List background transparent
                UITableView.appearance().backgroundColor = .clear
            }
            .navigationTitle("Articles")
            }
        }
    }
}

struct Article: Identifiable {
    let id = UUID()
    let title: String
    let content: String
    let icon: String
}

struct ArticleRowView: View {
    let article: Article
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: article.icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 40)
            
            Text(article.title)
                .font(.headline)
            
            Spacer()
        }
        .padding(.vertical, 5)
    }
}

struct ArticleDetailView: View {
    let article: Article
    
    var body: some View {
        ZStack {
            // Decorative neomorphic circles with different radii
            NeomorphicCircle(radius: 120, offset: CGSize(width: -100, height: -200))
                .allowsHitTesting(false)
            NeomorphicCircle(radius: 150, offset: CGSize(width: 150, height: 300))
                .allowsHitTesting(false)
            NeomorphicCircle(radius: 100, offset: CGSize(width: -120, height: 400))
                .allowsHitTesting(false)
            NeomorphicCircle(radius: 80, offset: CGSize(width: 200, height: 100))
                .allowsHitTesting(false)
            NeomorphicCircle(radius: 110, offset: CGSize(width: -150, height: 600))
                .allowsHitTesting(false)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Image(systemName: article.icon)
                            .font(.largeTitle)
                            .foregroundColor(.blue)
                        Spacer()
                    }
                    
                    Text(article.title)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text(article.content)
                        .font(.body)
                        .lineSpacing(5)
                }
                .padding()
            }
        }
        .navigationTitle(article.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}


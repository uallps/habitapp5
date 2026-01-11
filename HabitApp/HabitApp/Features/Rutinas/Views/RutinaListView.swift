//
//  RutinaListView.swift
//  HabitApp
//
//  Vista principal para gestionar rutinas
//
import SwiftUI

struct RutinaListView: View {
    @ObservedObject private var config: AppConfig

    init(config: AppConfig) {
        self.config = config
    }
    
    var body: some View {
        RutinaListContentView(
            rutinaStorageProvider: config.storageType == .swiftData
                ? SwiftDataRutinaStorageProvider.shared
                : JSONRutinaStorageProvider.shared,
            habitStorageProvider: config.storageProvider
        )
        // Si el usuario cambia JSON/SwiftData en Ajustes, forzamos recrear el ViewModel
        // para que Rutinas lea del mismo StorageProvider que el core.
        .id(config.storageType)
    }
}

private struct RutinaListContentView: View {
    @StateObject private var viewModel: RutinaViewModel
    @StateObject private var habitListViewModel: HabitListViewModel
    @State private var showingAddRutina = false
    @State private var habitCountCache: [UUID: Int] = [:]
    @State private var pendingDeletionRutinaIDs: [UUID] = []

    @State private var showingExecutionAlert = false
    @State private var executionAlertTitle = ""
    @State private var executionAlertMessage = ""

    init(rutinaStorageProvider: RutinaStorageProvider, habitStorageProvider: StorageProvider) {
        _viewModel = StateObject(wrappedValue: RutinaViewModel(
            storageProvider: rutinaStorageProvider,
            habitStorageProvider: habitStorageProvider
        ))
        _habitListViewModel = StateObject(wrappedValue: HabitListViewModel(storageProvider: habitStorageProvider))
    }

    var body: some View {
        NavigationStack {
            List {
                if !viewModel.rutinas.isEmpty {
                    ForEach(viewModel.rutinas) { rutina in
                        NavigationLink(destination: RutinaDetailView(
                            rutina: binding(for: rutina),
                            habitListViewModel: habitListViewModel,
                            rutinaViewModel: viewModel,
                            onSave: {
                                Task {
                                    await viewModel.updateRutina(rutina)
                                    await loadHabitCounts()
                                }
                            }
                        )) {
                            RutinaRowView(
                                rutina: rutina,
                                habitCount: habitCountCache[rutina.id] ?? rutina.habitoIds.count,
                                onToggleActiva: {
                                    Task {
                                        await viewModel.toggleRutinaActiva(rutina)
                                    }
                                },
                                onEjecutar: {
                                    Task {
                                        if let result = await viewModel.ejecutarRutina(rutina) {
                                            executionAlertTitle = "Rutina ejecutada"
                                            if result.totalHabits == 0 {
                                                executionAlertMessage = "Esta rutina no tiene hábitos."
                                            } else if result.markedAsCompleted == 0 {
                                                executionAlertMessage = "No había hábitos pendientes para hoy (0/\(result.totalHabits))."
                                            } else {
                                                executionAlertMessage = "Se marcaron \(result.markedAsCompleted)/\(result.totalHabits) hábitos como completados hoy."
                                            }
                                        } else {
                                            executionAlertTitle = "No se pudo ejecutar"
                                            executionAlertMessage = "La rutina está desactivada o hubo un error al guardar."
                                        }
                                        showingExecutionAlert = true
                                    }
                                }
                            )
                            .appCard(padding: 14)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .appListRowCard()
                        .contextMenu {
                            Button("Eliminar rutina") {
                                deleteRutina(rutina)
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                deleteRutina(rutina)
                            } label: {
                                Label("Eliminar", systemImage: "trash")
                            }
                            
                            Button {
                                Task {
                                    await viewModel.toggleRutinaActiva(rutina)
                                }
                            } label: {
                                Label(
                                    rutina.isActiva ? "Desactivar" : "Activar",
                                    systemImage: rutina.isActiva ? "pause.circle" : "play.circle"
                                )
                            }
                            .tint(.orange)
                        }
                    }
                    .onDelete { indexSet in
                        Task {
                            await viewModel.removeRutinas(atOffsets: indexSet)
                            await loadHabitCounts()
                        }
                    }
                }
            }
            .overlay {
                if viewModel.rutinas.isEmpty {
                    ContentUnavailableView {
                        Label {
                            Text("No hay rutinas")
                                .font(.title3)
                                .fontWeight(.semibold)
                        } icon: {
                            Image(systemName: "list.bullet.circle")
                                .font(.system(size: 60))
                                .foregroundStyle(.secondary)
                        }
                    } description: {
                        Text("Crea una rutina para agrupar tus hábitos")
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .appListContainer()
            .navigationTitle("Rutinas")
            .alert(
                pendingDeletionRutinaIDs.count > 1 ? "Eliminar rutinas" : "Eliminar rutina",
                isPresented: Binding(
                    get: { !pendingDeletionRutinaIDs.isEmpty },
                    set: { if !$0 { pendingDeletionRutinaIDs = [] } }
                )
            ) {
                Button("Eliminar", role: .destructive) {
                    confirmDeletion()
                }
                Button("Cancelar", role: .cancel) {
                    pendingDeletionRutinaIDs = []
                }
            } message: {
                if pendingDeletionRutinaIDs.count == 1,
                   let id = pendingDeletionRutinaIDs.first,
                   let rutina = viewModel.rutinas.first(where: { $0.id == id }) {
                    Text("¿Seguro que quieres eliminar \"\(rutina.nombre)\"?")
                } else {
                    Text("¿Seguro que quieres eliminar \(pendingDeletionRutinaIDs.count) rutinas?")
                }
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddRutina = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .alert(executionAlertTitle, isPresented: $showingExecutionAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(executionAlertMessage)
            }
            .sheet(isPresented: $showingAddRutina) {
                NavigationStack {
                    RutinaEditorView(
                        habitStorageProvider: viewModel,
                        onSave: { nuevaRutina in
                            Task {
                                await viewModel.addRutina(rutina: nuevaRutina)
                                await loadHabitCounts()
                                showingAddRutina = false
                            }
                        }
                    )
                }
            }
            .task {
                await viewModel.loadRutinas()
                await loadHabitCounts()
            }
        }
    }
    
    private func binding(for rutina: Rutina) -> Binding<Rutina> {
        guard let index = viewModel.rutinas.firstIndex(where: { $0.id == rutina.id }) else {
            fatalError("Rutina not found")
        }
        return Binding(
            get: { viewModel.rutinas[index] },
            set: { viewModel.rutinas[index] = $0 }
        )
    }
    
    private func deleteRutina(_ rutina: Rutina) {
        pendingDeletionRutinaIDs = [rutina.id]
    }
    
    private func confirmDeletion() {
        let idsToDelete = pendingDeletionRutinaIDs
        pendingDeletionRutinaIDs = []

        let originalOffsets = IndexSet(idsToDelete.compactMap { id in
            viewModel.rutinas.firstIndex(where: { $0.id == id })
        })

        guard !originalOffsets.isEmpty else { return }

        Task {
            await viewModel.removeRutinas(atOffsets: originalOffsets)
            await loadHabitCounts()
        }
    }
    
    private func loadHabitCounts() async {
        var counts: [UUID: Int] = [:]
        for rutina in viewModel.rutinas {
            let habitos = await viewModel.getHabitosForRutina(rutina)
            counts[rutina.id] = habitos.count
        }
        habitCountCache = counts
    }
}

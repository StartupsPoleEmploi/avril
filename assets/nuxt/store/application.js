export const state = () => ({
  heures: 0,
  remplissage: 0,
  monDossier: null,
  displayExperienceStepper: false,
  displayFormationStepper: false,
  tab: 1,
})

export const mutations = {

  // Remplissage
  addRemplissage (state, val) {
    state.remplissage = val
  },
  enableMonDossier (state) {
    state.monDossier = true
  },

  enableExperienceStepper(state) {
    state.displayExperienceStepper = true;
  },
  disableExperienceStepper(state) {
    state.displayExperienceStepper = false;
  },

  enableFormationStepper(state) {
    state.displayFormationStepper = true;
  },
  disableFormationStepper(state) {
    state.displayFormationStepper = false;
  },

  changeTab(state, tab) {
    state.tab = tab;
  },

}

export const state = () => ({
  experiences: [],
  titres: [],
  formationsContinues: [],
  formations: {
    classe: null,
    diplome: null,
    // certification: null,
  },
  heures: 0,
})

// - experiences
// - duree
// - periode

export const mutations = {
  new (state) {
    state.experiences.push({
      fonction: null,
      entreprise: null,
      adresseEntreprise: null,
      famille: null,
      status: null,
      activities: [],
      periodes: []
    })
  },
  addFonction (state, fonction) {
    state.experiences[state.experiences.length - 1].fonction = fonction
  },
  addEntreprise (state, entreprise) {
    state.experiences[state.experiences.length - 1].entreprise = entreprise
  },
  addAdresseEntreprise (state, adresse) {
    state.experiences[state.experiences.length - 1].adresseEntreprise = adresse
  },
  addFamille (state, famille) {
    state.experiences[state.experiences.length - 1].famille = famille
  },
  addStatus (state, status) {
    state.experiences[state.experiences.length - 1].status = status
  },
  addPeriode (state, periode) {
    state.experiences[state.experiences.length - 1].periode = periode
  },
  addDuree (state, duree) {
    state.experiences[state.experiences.length - 1].duree = duree
  },
  addTemps (state, temps) {
    state.experiences[state.experiences.length - 1].temps = temps
  },
  // addPrecision (state, precision) {
  //   state.experiences[state.experiences.length - 1].precision = precision
  // },
  addHours (state, heure) {
    state.heures = state.heures + heure
  },
  // -------------
  // FORMATIONS
  // -------------
  addClasse (state, classe) {
    state.formations.classe = classe
  },
  addDiplome (state, diplome) {
    state.formations.diplome = diplome
  },
  addAutre (state, autre) {
    state.formations.autre = autre
  },
  addComparatibilite (state, comparatibilite) {
    state.formations.comparatibilite = comparatibilite
  },
  addPartie (state, val) {
    state.formations.partie = val
  },
  addCertification (state, val) {
    state.formations.certification = val
  },
  addRNCP (state, val) {
    state.formations.rncp = val
  },
  addFormations (state, val) {
    state.formations.formations = val
  },

  // Certifications
  chooseType (state, val) {
    state.certification = val
  },

  addActivite (state, val) {
    state.experiences[state.experiences.length - 1].activities.push(val)
  },

  addTitre (state, val) {
    state.titres.push(val)
  },

  addPeriodes (state, val) {
    state.experiences[state.experiences.length - 1].periodes.push(val)
  },

  addFormationContinue (state, val) {
    state.formationsContinues.push(val)
  },


  remove (state, { todo }) {
    state.experiences.splice(state.experiences.indexOf(todo), 1)
  },

}

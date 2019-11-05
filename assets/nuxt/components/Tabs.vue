<template>

  <div class="navigation-tabs">

      <nuxt-link to="/formations"  :class="tab == 1 ? 'navigation-tab navigation-active is-vertical-center' : 'navigation-tab is-vertical-center'">
        <div>
          <span v-if="formationIsOk">
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
                <path d="M12,0A12,12,0,1,0,24,12,12.014,12.014,0,0,0,12,0Zm6.927,8.2-6.845,9.289a1.011,1.011,0,0,1-1.43.188L5.764,13.769a1,1,0,1,1,1.25-1.562l4.076,3.261,6.227-8.451A1,1,0,1,1,18.927,8.2Z"></path>
            </svg>
          </span>
          <span class="title is-4">Ma formation</span>
        </div>
      </nuxt-link>

      <nuxt-link to="/experiences" :class="tab == 0 ? 'navigation-tab navigation-active is-vertical-center' : 'navigation-tab is-vertical-center'">
        <div class="title is-4">Mes expériences professionnelles</div>
        <div class="progress-vision">
          <div class="progress__bar --hours"><div class="progress__bar--suivi" :style="`width:${pourcentage}%`"></div></div>
          <p v-if="heures < 1607">Vous avez ajouté <strong>{{Math.round(heures)}}</strong> heure<span v-if="(heures) > 0">s</span> sur 1607 demandées.</p>
          <p v-if="heures >= 1607">Vous avez renseigné <strong>{{Math.round(heures)}}</strong> heure<span v-if="heures > 0">s</span>.</p>
        </div>
      </nuxt-link>

    </div>


</template>
<script>
import _ from 'lodash';

export default {
  computed: {
    heures () {
      return this.$store.state.experiences.heures
    },
    formationIsOk(){
      let valeurs = this.$store.state.experiences;
      if( valeurs.titres.length != 0 &&
          valeurs.formationsContinues.length != 0 &&
          !_.isEmpty( valeurs.formations.classe ) &&
          !_.isEmpty( valeurs.formations.diplome )){
            return true;
          }
      return false;

    },
    monDossier () {
      return this.$store.state.application.monDossier
    },
    pourcentage () {
      if( (this.$store.state.experiences.heures*100)/1607 > 100 )
        return 100
      else
        return (this.$store.state.experiences.heures*100)/1607
    },
    tab () {
      return this.$store.state.application.tab
    }
  },
}
</script>

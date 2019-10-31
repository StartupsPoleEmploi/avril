<template>

  <div class="navigation-tabs">

      <nuxt-link to="/formations"  :class="tab == 1 ? 'navigation-tab navigation-active is-vertical-center' : 'navigation-tab is-vertical-center'">
        <!-- <div class="navigation-indicator">2</div> -->
        <!-- <div v-if="heures < 1607">
          <div class="title is-4">Ma formation</div>
          <p class="small">Vous devez d'abord renseigner vos expériences professionnelles</p>
          <div class="navigation-locked">
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
                <title>lock-8</title>
                <rect x="16.746" y="17.5" width="4.754" height="2" rx="0.25" ry="0.25"></rect>
                <path d="M17,21a1.752,1.752,0,0,1-1.75-1.75v-5A1.752,1.752,0,0,1,17,12.5H21.25a.25.25,0,0,0,.25-.25V11.5a2,2,0,0,0-2-2h-.75V6.75a6.75,6.75,0,0,0-13.5,0V9.5H4.5a2,2,0,0,0-2,2V22a2,2,0,0,0,2,2h15a2,2,0,0,0,2-2v-.75a.25.25,0,0,0-.25-.25ZM7.75,6.75a4.25,4.25,0,0,1,8.5,0V9a.5.5,0,0,1-.5.5H8.25a.5.5,0,0,1-.5-.5Z"></path>
                <rect x="16.746" y="14" width="4.754" height="2" rx="0.25" ry="0.25"></rect>
            </svg>
          </div>
        </div> -->
        <div>
          <div class="title is-4">Ma formation</div>
        </div>
      </nuxt-link>

      <nuxt-link to="/experiences" :class="tab == 0 ? 'navigation-tab navigation-active is-vertical-center' : 'navigation-tab is-vertical-center'">
        <!-- <div class="navigation-indicator">1</div> -->
        <div class="title is-4">Mes expériences professionnelles</div>
        <div class="progress-vision">
          <div class="progress__bar --hours"><div class="progress__bar--suivi" :style="`width:${pourcentage}%`"></div></div>
          <p v-if="heures < 1607">Vous avez ajouté <strong>{{heures}}</strong> heure<span v-if="(heures) > 0">s</span> sur 1607 demandées.</p>
          <p v-if="heures >= 1607">Vous avez renseigné <strong>{{heures}}</strong> heure<span v-if="heures > 0">s</span>.</p>
        </div>
      </nuxt-link>

      <nuxt-link to="/" class="button is-default" style="margin-top:2rem" disabled>
        Transmettre à mon certificateur
      </nuxt-link>

      <!-- <nuxt-link to="/certification"  :class="tab == 2 ? 'navigation-tab navigation-active is-vertical-center' : 'navigation-tab is-vertical-center'">
        <div class="navigation-indicator">3</div>
        <span v-if="monDossier != true">
          <div class="title is-4">Mon livret 1</div>
          <p class="small">Vous devez d'abord renseigner vos formations</p>
          <div class="navigation-locked">
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
                <title>lock-8</title>
                <rect x="16.746" y="17.5" width="4.754" height="2" rx="0.25" ry="0.25"></rect>
                <path d="M17,21a1.752,1.752,0,0,1-1.75-1.75v-5A1.752,1.752,0,0,1,17,12.5H21.25a.25.25,0,0,0,.25-.25V11.5a2,2,0,0,0-2-2h-.75V6.75a6.75,6.75,0,0,0-13.5,0V9.5H4.5a2,2,0,0,0-2,2V22a2,2,0,0,0,2,2h15a2,2,0,0,0,2-2v-.75a.25.25,0,0,0-.25-.25ZM7.75,6.75a4.25,4.25,0,0,1,8.5,0V9a.5.5,0,0,1-.5.5H8.25a.5.5,0,0,1-.5-.5Z"></path>
                <rect x="16.746" y="14" width="4.754" height="2" rx="0.25" ry="0.25"></rect>
            </svg>
          </div>
        </span>
        <span>
          <div class="title is-4">Mon livret 1</div>
        </span>
      </nuxt-link> -->

    </div>


</template>
<script>
import _ from 'lodash';

export default {
  computed: {
    heures () {
      return this.$store.state.experiences.heures
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

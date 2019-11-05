<template>

  <div class="form-header" v-if="displayExperienceStepper == true">

    <!-- <div class="field" v-if="slugIndex == 5" style="margin-right:3rem">
      <div class="control">
        <nuxt-link to="/experiences/fonction" class="is-ok button is-dark is-pulled-right">
          Ajouter une expérience
        </nuxt-link>
      </div>
    </div> -->

    <h3 class="title is-6">Ajouter une expérience professionnelle</h3>
    <div class="avril-stepper-container">

      <div class="avril-stepper">
    <ul class="steps is-small is-centered has-content-centered">
      <li :class="slugIndex == 1 || slugIndex == 0 ? 'steps-segment is-active' : 'steps-segment'">
         <nuxt-link to="/experiences/fonction" :class="slugIndex == 1 || slugIndex == 0 ? 'steps-marker is-hollow' : 'steps-marker'"></nuxt-link>
         <div class="steps-content is-divider-content">
           <nuxt-link class="is-size-6" to="/experiences/fonction">Mon expérience</nuxt-link>
         </div>
       </li>
       <li :class="slugIndex == 2 ? 'steps-segment is-active' : 'steps-segment'">
         <nuxt-link to="/experiences/famille"  :class="slugIndex == 2 ? 'steps-marker is-hollow' : 'steps-marker'"></nuxt-link>
         <div class="steps-content is-divider-content">
           <nuxt-link class="is-size-6" to="/experiences/famille">Famille</nuxt-link>
         </div>
       </li>
       <li :class="slugIndex == 3 ? 'steps-segment is-active' : 'steps-segment'">
         <nuxt-link to="/experiences/status"  :class="slugIndex == 3 ? 'steps-marker is-hollow' : 'steps-marker'"></nuxt-link>
         <div class="steps-content is-divider-content">
           <nuxt-link class="is-size-6" to="/experiences/status">Statut</nuxt-link>
         </div>
       </li>
       <li :class="slugIndex == 4 ? 'steps-segment is-active' : 'steps-segment'">
         <nuxt-link to="/experiences/periode"  :class="slugIndex == 4 ? 'steps-marker is-hollow' : 'steps-marker'"></nuxt-link>
         <div class="steps-content is-divider-content">
           <nuxt-link class="is-size-6" to="/experiences/periode">Période</nuxt-link>
         </div>
       </li>
       <li :class="slugIndex == 5 ? 'steps-segment is-active' : 'steps-segment'">
         <nuxt-link to="/experiences/precision"  :class="slugIndex == 5 ? 'steps-marker is-hollow' : 'steps-marker'"></nuxt-link>
         <div class="steps-content is-divider-content">
           <nuxt-link class="is-size-6" to="/experiences/precision">Activités</nuxt-link>
         </div>
       </li>
     </ul>
  </div>
    </div>
  </div>
</div>
</template>
<script>
import _ from 'lodash';

export default {
  computed: {
    heures () {
      return this.$store.state.experiences.heures
    },
    displayExperienceStepper () {
      return this.$store.state.application.displayExperienceStepper
    },
  },
  watch: {
    $route (to, from) {
      this.slugIndex = _.findIndex(this.cerfa, ['slug', this.$route.name])
    }
  },
  data: () => ({
    current: 0,
    slugIndex: 0,
    cerfa:[{
      slug: 'experiences',
      title: "Mes expériences",
    },
    {
      slug: 'experiences-fonction',
      title: "Mes formations",
    },
    {
      slug: 'experiences-famille',
      title: "Mes formations",
    },
    {
      slug: 'experiences-status',
      title: "Mes formations",
    },
    {
      slug: 'experiences-periode',
      title: "Mes formations",
    },
    {
      slug: 'experiences-precision',
      title: "Mes formations",
    },
    {
      slug: 'formations',
      title: "Mes formations",
    },
    {
      slug: 'formations-diplome',
      title: "Mes formations",
    },
    {
      slug: 'formations-autre',
      title: "Mes formations",
    },
    {
      slug: 'formations-comparatibilite',
      title: "Mes formations",
    },
    {
      slug: 'formations-certification',
      title: "Mes formations",
    },
    {
      slug: 'formations-rncp',
      title: "Mes formations",
    },
    {
      slug: 'formations-formations',
      title: "Mes formations",
    },
  ],
  })
}
</script>

<template>
  <div class="form-header" v-if="displayFormationStepper == true">

    <div class="field" v-if="slugIndex == 12" style="margin-right:3rem">
      <div class="control">
        <nuxt-link to="/experiences/fonction" class="is-ok button is-dark is-pulled-right">
          J'ai fini, aller aux expériences
        </nuxt-link>
      </div>
    </div>

    <h3 class="title is-6">Ajouter une formation</h3>
    <div class="avril-stepper-container">
      <div class="avril-stepper">
    <ul class="steps is-small is-centered has-content-centered">
      <li :class="slugIndex == '' || slugIndex == 6 ? 'steps-segment is-active' : 'steps-segment'">
         <nuxt-link to="/formations" :class="slugIndex == '' || slugIndex == 6 ? 'steps-marker is-hollow' : 'steps-marker'"></nuxt-link>
         <div class="steps-content is-divider-content">
           <nuxt-link class="is-size-6" to="/formations">Classe</nuxt-link>
         </div>
       </li>
       <li :class="slugIndex == 7 ? 'steps-segment is-active' : 'steps-segment'">
         <nuxt-link to="/formations/diplome" :class="slugIndex == 7 ? 'steps-marker is-hollow' : 'steps-marker'"></nuxt-link>
         <div class="steps-content is-divider-content">
           <nuxt-link class="is-size-6" to="/formations/diplome">Diplôme(s)</nuxt-link>
         </div>
       </li>
       <li :class="slugIndex == 8 ? 'steps-segment is-active' : 'steps-segment'">
         <nuxt-link to="/formations/autre" :class="slugIndex == 8 ? 'steps-marker is-hollow' : 'steps-marker'"></nuxt-link>
         <div class="steps-content is-divider-content">
           <nuxt-link class="is-size-6" to="/formations/autre">Certification</nuxt-link>
         </div>
       </li>
       <li :class="slugIndex == 11 ? 'steps-segment is-active' : 'steps-segment'">
         <nuxt-link to="/formations/rncp" :class="slugIndex == 11 ? 'steps-marker is-hollow' : 'steps-marker'"></nuxt-link>
         <div class="steps-content is-divider-content">
           <nuxt-link class="is-size-6" to="/formations/rncp">RNCP</nuxt-link>
         </div>
       </li>
       <li :class="slugIndex == 12 ? 'steps-segment is-active' : 'steps-segment'">
         <nuxt-link to="/formations/formations" :class="slugIndex == 12 ? 'steps-marker is-hollow' : 'steps-marker'"></nuxt-link>
         <div class="steps-content is-divider-content">
           <nuxt-link class="is-size-6" to="/formations/formations">Formations</nuxt-link>
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
    displayFormationStepper () {
      return this.$store.state.application.displayFormationStepper
    },
  },
  watch: {
    $route (to, from) {
      this.slugIndex = _.findIndex(this.cerfa, ['slug', this.$route.name])
      console.log(this.slugIndex);
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

<template>

  <div class="container">

    <div class="avril-layout">


      <!-- Tabs -->
      <div class="avril-navigation">
        <div class="navigation-header">
          <div class="avril-back">
            <a href="/livret-1">
              <svg xmlns="http://www.w3.org/2000/svg" id="Bold" viewBox="0 0 24 24">
                <title>arrow-left-1</title>
                <path d="M4.5,12a2.3,2.3,0,0,1,.78-1.729L16.432.46a1.847,1.847,0,0,1,2.439,2.773L9.119,11.812a.25.25,0,0,0,0,.376l9.752,8.579a1.847,1.847,0,1,1-2.439,2.773L5.284,13.732A2.31,2.31,0,0,1,4.5,12Z"></path>
              </svg> retour
            </a>
          </div>
        </div>
        <div class="navigation-tabs">
          <h3 class="navigation-title title is-4">Dossier de recevabilité</h3>
          <h4 class="navigation-subtitle title is-5">CAP - Accompagnant éducatif - Petite enfance</h4>
          <div class="navigation-progressbar progress__bar">
            <div class="progress__bar--suivi" :style="`width:${remplissage}%`"></div>
          </div>
          <div class="">
            {{Math.round(remplissage)}}% complété
          </div>
          <Tabs></Tabs>
        </div>
      </div>


      <!-- Fake form + aide -->
      <div class="avril-content">

        <div class="experiences-header">

          <div class="field has-addons is-pulled-left">
            <p class="control">
              <a href="#" @click="back" :class="!displayBack ? 'button lefty is-static' : 'button lefty'">
                <ArrowLeft />
              </a>
            </p>
            <p class="control">
              <a href="#" @click="next" :class="!displayNext ? 'button righty is-static' : 'button righty'">
                <ArrowRight />
              </a>
            </p>
          </div>

          <div class="field is-pulled-right">
            <div class="control">
              <nuxt-link to="/recapitulatif" :class="slugIndex == 5 ? 'is-ok button is-dark' : 'is-ok button is-default'">
                Enregistrer mon livret de recevabilité
              </nuxt-link>
              <!-- <nuxt-link to="/experiences/fonction" class="is-ok button is-default is-pulled-right" style="margin-right:1rem">
                Ajouter une nouvelle expérience
              </nuxt-link> -->
            </div>
          </div>

        </div>

        <div class="avril-form-help-container">

          <StepperExperience/>
          <StepperFormation/>
          <nuxt />

        </div>

      </div>

    </div>

  </div>

</div>
</template>

<script>
import _ from 'lodash';
import Actions from '~/components/Actions.vue';
import Tabs from '~/components/Tabs.vue';
import StepperExperience from '~/components/stepper-experience.vue';
import StepperFormation from '~/components/stepper-formation.vue';

import ArrowLeft from '@/assets/svgs/keyboard-arrow-left.svg';
import ArrowRight from '@/assets/svgs/keyboard-arrow-right.svg';

  export default {
    components: {
      Actions,
      Tabs,
      StepperExperience,
      StepperFormation,
      ArrowLeft,
      ArrowRight,
    },
    computed: {
      heures () {
        return this.$store.state.experiences.heures
      },
      remplissage () {
        let counter = 0;

        let sections = 6;
        let valeurs = this.$store.state.experiences;

        if( valeurs.heures > 1607 ) counter++;
        if( valeurs.titres.length != 0 ) counter++;
        if( valeurs.formationsContinues.length != 0 ) counter++;

        if( !_.isEmpty( valeurs.formations.classe ) ) counter++;
        if( !_.isEmpty( valeurs.formations.diplome ) ) counter++;
        if( !_.isEmpty( valeurs.formations.certification ) ) counter++;

        let sut = ( counter / sections ) * 100;
        this.$store.commit('application/addRemplissage', sut);
        return sut;
      },
    },
    methods: {
      back: function (e) {
        if(this.slugIndex == this.way[0]){
          this.displayBack = false;
          return false;
        }
        let previous = this.way[(_.indexOf(this.way, this.slugIndex)-1)];
        let url = this.cerfa[previous].slug.replace('-', '/');
        this.$router.push({
            path: '/' + url
        });
      },
      next: function (e) {
        if(_.indexOf(this.way, this.slugIndex) == this.way.length - 1){
          this.displayNext = false;
          return false;
        }
        let next = this.way[(_.indexOf(this.way, this.slugIndex)+1)];
        let url = this.cerfa[next].slug.replace('-', '/');
        this.$router.push({
            path: '/' + url
        });
      }
    },
    mounted() {
      this.slugIndex = _.findIndex(this.cerfa, ['slug', this.$route.name])
    },
    watch: {
      $route (to, from) {
        this.slugIndex = _.findIndex(this.cerfa, ['slug', this.$route.name])
        if(this.slugIndex != this.way[0]) this.displayBack = true;
        if(this.slugIndex == this.way[this.way.length-1]) this.displayNext = false;
      }
    },
    afterCreated() {

    },
    data: () => ({
      current: 0,
      slugIndex: 0,
      way: [6,7,11,12,0,1,2,3,4,5],
      displayBack: false,
      displayNext: true,
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

<style>
html {
  font-family: 'Nunito Sans', -apple-system, BlinkMacSystemFont, 'Segoe UI',
    Roboto, 'Helvetica Neue', Arial, sans-serif;
  font-size: 16px;
  word-spacing: 1px;
  -ms-text-size-adjust: 100%;
  -webkit-text-size-adjust: 100%;
  -moz-osx-font-smoothing: grayscale;
  -webkit-font-smoothing: antialiased;
  box-sizing: border-box;
}

*,
*:before,
*:after {
  box-sizing: border-box;
  margin: 0;
}

.button--green {
  display: inline-block;
  border-radius: 4px;
  border: 1px solid #3b8070;
  color: #3b8070;
  text-decoration: none;
  padding: 10px 30px;
}

.button--green:hover {
  color: #fff;
  background-color: #3b8070;
}

.button--grey {
  display: inline-block;
  border-radius: 4px;
  border: 1px solid #35495e;
  color: #35495e;
  text-decoration: none;
  padding: 10px 30px;
  margin-left: 15px;
}

.button--grey:hover {
  color: #fff;
  background-color: #35495e;
}
</style>

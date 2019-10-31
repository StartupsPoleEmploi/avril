<template>
  <div>
    <div class="avril-didacticiel">

<!-- Tutorial -->
      <div class="avril-tutorial">
        <div v-swiper:mySwiper="swiperOption">
          <div class="swiper-wrapper">
            <div class="swiper-slide">
              <p class="title is-4">
                Vous allez créer et remplir votre livret 1 en ligne
              </p>
            </div>
            <div class="swiper-slide">
              <p class="title is-4">
                Munissez-vous de vos bulletins de salaire
              </p>
            </div>
            <div class="swiper-slide">
              <p class="title is-4">
                Vous aurez 3 grandes parties à remplir, celle des expériences professionnelles est celle qui demande le plus d'attentions
              </p>
            </div>
          </div>
          <div class="swiper-pagination swiper-pagination-bullets"></div>
          <div class="swiper-button swiper-button-prev" slot="button-prev"></div>
          <div class="swiper-button swiper-button-next" slot="button-next"></div>
        </div>
      </div>

<!-- Preformulaire -->
      <!-- <div class="avril-preform">
        <div class="field">
          <label class="label">Langue&nbsp; | &nbsp;Language&nbsp; | &nbsp;言語&nbsp; | &nbsp;لغة &nbsp;</label>
          <div class="control">
            <div class="select is-large">
              <select>
                <option>Français</option>
                <option>Anglais</option>
                <option>Arabe</option>
                <option>Chinois</option>
                <option>Marseillaise</option>
              </select>
            </div>
          </div>
        </div>
      </div> -->

<!-- bouton start -->
      <div class="avril-start">
        <nuxt-link to="/formations" class="is-ok button is-pink">
          Démarrer ma demande de recevabilité
        </nuxt-link>
      </div>

    </div>


  </div>
</template>

<script>

export default {
  data () {
    return {
      swiperOption: {
        autoplay: {
          delay: 4000,
        },
        loop: false,
        slidesPerView: 'auto',
        centeredSlides: true,
        setWrapperSize: true,
        navigation: {
          nextEl: '.swiper-button-next',
          prevEl: '.swiper-button-prev'
        },
        pagination: {
          el: '.swiper-pagination',
          type: 'bullets',
        },
        on: {
          slideChange() {
            console.log('onSlideChangeEnd', this);
          },
          tap() {
            console.log('onTap', this);
          }
        }
      }
    }
  }
}
</script>

<style>
.select:not(.is-multiple):not(.is-loading)::after, .navbar-link:not(.is-arrowless)::after {
  border: 3px solid #000;
  border-right: 0;
  border-top: 0;
  margin-top: -0.65em;
  height: 0.425em;
  width: 0.425em;
  right: 0.6em;
}
</style>

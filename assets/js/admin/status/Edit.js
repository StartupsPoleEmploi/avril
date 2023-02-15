import React, { Component } from 'react';
import DatePicker, { registerLocale }  from 'react-datepicker';
import fr from 'date-fns/locale/fr';

registerLocale('fr', fr)
const DATE_FORMAT = 'DD/MM/YYYY à HH[h]mm';

import 'react-datepicker/dist/react-datepicker.css';
import '../../../css/admin/react-datepicker.scss';


class Edit extends React.Component {
  state = {
    status: this.props.status || {},
  }

  editStatus(key, value) {
    this.setState({
      status: {
        ...this.state.status,
        [key]: ((key.indexOf("_at") > -1 && value) ? value.toISOString() : value)
      }
    })
  }

  submitStatus(e) {
    e.preventDefault();
    this.props.createStatus(this.state.status);
  }

  render() {
    console.log(this.state.status)
    return (
      <form action="/admin/status" method="POST" className="form-horizontal" onSubmit={e => this.submitStatus(e)}>
        <input type="hidden" name="_csrf_token" value={this.props.token} />
        <div className="form-group">
          <label htmlFor="status" className="col-sm-2 control-label">Niveau</label>
          <div className="col-sm-10">
            <select
              className="form-control"
              required
              onChange={e => this.editStatus('level', e.target.value)}
              value={this.state.status && this.state.status.level || ''}
            >
              <option className="text-info" value="info">Info (bleu clair)</option>
              <option className="text-primary" value="primary">Primary (bleu foncé)</option>
              <option className="text-warning" value="warning">Warning (jaune)</option>
              <option className="text-danger" value="danger">Danger (rouge)</option>
              <option className="text-success" value="success">Success (vert)</option>
            </select>
          </div>
        </div>
        <div className="form-group">
          <label htmlFor="message" className="col-sm-2 control-label">
            Contenu
          <br />
          <small>(Possibilité d'utiliser le format <a href="https://guides.github.com/features/mastering-markdown/" target="_blank">markdown</a>)</small>
          </label>
          <div className="col-sm-10">
            <textarea
              className="form-control"
              rows="5"
              required
              onChange={e => this.editStatus('message', e.target.value)}
              value={this.state.status && this.state.status.message || ''}
            />
          </div>
        </div>
        <div className="form-group">
          <label htmlFor="starts_at" className="col-sm-2 control-label">Date de début</label>
          <div className="col-sm-10">
            <DatePicker
              locale="fr"
              timeCaption="Heure"
              className="form-control"
              showTimeSelect
              dateFormat="dd/MM/yyyy HH:mm"
              minDate={new Date()}
              onChange={date => this.editStatus('starts_at', date)}
              selected={this.state.status && this.state.status.starts_at && new Date(this.state.status.starts_at)}
            />
          </div>
        </div>
        <div className="form-group">
          <label htmlFor="ends_at" className="col-sm-2 control-label">Date de fin</label>
          <div className="col-sm-10">
            <DatePicker
              locale="fr"
              timeCaption="Heure"
              className="form-control"
              showTimeSelect
              dateFormat="dd/MM/yyyy HH:mm"
              // minDate={this.state.status && this.state.status.starts_at && new Date(this.state.status.starts_at)}
              minDate={new Date()}
              onChange={date => this.editStatus('ends_at', date)}
              selected={this.state.status && this.state.status.ends_at && new Date(this.state.status.ends_at)}
            />
          </div>
        </div>
        <div className="form-group">
          <div className="col-sm-offset-2 col-sm-10">
            <div className="checkbox">
              <label>
                <input
                  type="checkbox"
                  onChange={e => this.editStatus('home_only', !this.state.status?.home_only)}
                  checked={!!this.state.status?.home_only}
                /> Page d'accueil uniquement
              </label>
            </div>
          </div>
        </div>
        <div className="form-group">
          <div className="col-sm-offset-2 col-sm-10">
            <div className="checkbox">
              <label>
                <input
                  type="checkbox"
                  onChange={e => this.editStatus('unclosable', !this.state.status?.unclosable)}
                  checked={!!this.state.status?.unclosable}
                /> Empêcher la fermeture du message
              </label>
            </div>
          </div>
        </div>
        <div className="form-group">
          <label htmlFor="status" className="col-sm-2 control-label">Image</label>
          <div className="col-sm-10">
            <select
              className="form-control"
              onChange={e => this.editStatus('image', e.target.value)}
              value={this.state.status && this.state.status.image || ''}
            >
              <option value="">Aucune</option>
              <option value="certificateur.svg">Certificateur</option>
              <option value="couple.svg">Couple</option>
              <option value="group.png">Groupe</option>
              <option value="mon-diplome.png">Diplôme</option>
              <option value="recevabilite.svg">Recevabilité</option>
              <option value="tampon-vae.svg">Tampon</option>
              <option value="Reva-logo-experimentation.svg">REVA</option>
            </select>
          </div>
        </div>
        <div className="form-group">
          <div className="col-sm-offset-2 col-sm-2">
            <button type="submit" className="btn btn-primary">Enregistrer</button>
          </div>
          <div className="col-sm-2">
            <button className="btn btn-info" onClick={e => this.props.editStatus('')}>Annuler</button>
          </div>
        </div>
      </form>
    );
  }
}

export default Edit;
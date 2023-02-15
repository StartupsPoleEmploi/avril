import React, { Component } from 'react';
import { render } from 'react-dom';

import ShowStatus from './status/Show';
import EditStatus from './status/Edit';

class StatusEditor extends React.Component {
  state = {
    status: this.props.status,
    editingId: '',
    feedback: null,
  }

  createStatus(data) {
    $.ajax('/admin/status', {
      method: 'POST',
      data,
      success: status => {
        this.setState({
          status,
          editingId: '',
          feedback: {
            success: true,
            message: 'Le bandeau a bien été soumis.'
          }
        })
      },
      fail: () => {
        this.setState({
          editingId: '',
          feedback: {
            success: false,
            message: 'Une erreur est survenue, ... sorry!'
          }
        })
      }
    });
  };

  deleteStatus(id) {
    $.ajax(`/admin/status?id=${id}`, {
      method: 'delete',
      success: status => {
        this.setState({
          status,
          feedback: {
            success: true,
            message: 'Le bandeau a bien été supprimé.'
          }
        })
      }
    });
  };


  editStatus(id) {
    this.setState({
      editingId: id,
      feedback: null,
    });
  }

  render() {
    return (
      <div>
        {
          this.state.feedback && (
            <div className={`alert alert-${this.state.feedback.success ? 'success' : 'danger'}`}>
              {this.state.feedback.message}
            </div>
          )
        }
        <div>
          <h1 className="text-center">Bandeau informatif</h1>
          <hr className="invisible" />
          { this.state.editingId ?
            <EditStatus
              status={this.state.status.find(({id}) => id === this.state.editingId)}
              token={this.props.token}
              editStatus={id => this.editStatus(id)}
              createStatus={data => this.createStatus(data)}
            /> : (
              <div>
                {this.state.status.length > 1 &&
                  <div className="text-center">
                    <h3>Les bandeaux seront affichés dans l'ordre suivant: </h3>
                    <p>(NB: pour modifier l'ordre, éditer le message le remet en bas de la file)</p>
                    <hr className="invisible" />
                  </div>
                }
                { this.state.status.map(status =>
                  <div key={status.id}>
                    <ShowStatus
                      status={status}
                      editStatus={id => this.editStatus(id)}
                      deleteStatus={id => this.deleteStatus(id)}
                    />
                  </div>
                )}
                { !this.state.status.length && (
                  <p>Aucun bandeau informatif enregistré actuellement.</p>
                )}
                <hr className="invisible" />
                <button onClick={() => this.editStatus('new')} className="btn btn-primary">Créer un nouveau bandeau</button>
              </div>
            )
          }
        </div>
      </div>
    );
  }
}

document.addEventListener('DOMContentLoaded', e => {
  const $statusEditor = document.getElementById('status-editor');
  if ($statusEditor) {
    $.ajax('/admin/status')
      .then(status => {
        render( <StatusEditor token={$statusEditor.dataset.token} status={status} />, $statusEditor)
      })
  }
})




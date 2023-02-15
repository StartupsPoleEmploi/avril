import React, { Component } from 'react';
import {markdown} from 'markdown';

class Show extends React.Component {

  renderDateRange() {
    if (this.props.status) {
      if (this.props.status.starts_at && this.props.status.ends_at)
        return `du ${moment(this.props.status.starts_at).format(DATE_FORMAT)} au ${moment(this.props.status.ends_at).format(DATE_FORMAT)}`;
      if (this.props.status.starts_at)
        return `à partir du ${moment(this.props.status.starts_at).format(DATE_FORMAT)}`
      if (this.props.status.ends_at)
        return `jusqu'au ${moment(this.props.status.ends_at).format(DATE_FORMAT)}`
      return 'sans limite de date';
    }
  }

  render() {
    return (
      <div>
        <p>
          Ce message sera affiché {this.renderDateRange()}
          {this.props.status.home_only ? ' sur la page d\'accueil uniquement' : ''}
          {this.props.status.unclosable ? ' sans possibilité de fermer le message' : ''}
          :
        </p>
        <div className="row">
          <div className="col-sm-10">
            <div className={`app-status alert alert-${this.props.status.level}`}>
              <div className="row">
                <div className="col-sm-9">
                  <span dangerouslySetInnerHTML={{__html: markdown.toHTML(this.props.status.message)}} />
                </div>
                <div className="col-sm-3">
                  {this.props.status.image && (
                    <img src={`/images/${this.props.status.image}`} style={{maxWidth: '100%'}} />
                  )}
                </div>
              </div>
            </div>
          </div>
          <div className="col-sm-1">
            <button onClick={e => this.props.editStatus(this.props.status.id)} className="btn btn-primary"><span className="fa fa-edit"></span></button>
          </div>
          <div className="col-sm-1">
            <button onClick={e => this.props.deleteStatus(this.props.status.id)} className="btn btn-danger"><span className="fa fa-trash"></span></button>
          </div>
        </div>
      </div>
    );
  }
}

export default Show;